-- 00004_database_hardening.sql
-- Description: Enterprise hardening with audit logging, admin RLS, and performance indexing.

-- ==========================================
-- 1. Audit Logging System
-- ==========================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name text NOT NULL,
    record_id uuid NOT NULL,
    action text NOT NULL, -- INSERT, UPDATE, DELETE
    old_data jsonb,
    new_data jsonb,
    changed_by uuid REFERENCES public.profiles(id),
    created_at timestamptz DEFAULT now()
);

-- RLS for Audit Logs: Only admins can see them
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view all audit logs." ON public.audit_logs;
CREATE POLICY "Admins can view all audit logs." ON public.audit_logs 
    FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Generic function to process audit logs
CREATE OR REPLACE FUNCTION public.process_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, TG_OP, to_jsonb(OLD), auth.uid());
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(NEW), auth.uid());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply Triggers
DROP TRIGGER IF EXISTS audit_orders_trigger ON public.orders;
CREATE TRIGGER audit_orders_trigger AFTER INSERT OR UPDATE OR DELETE ON public.orders FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

DROP TRIGGER IF EXISTS audit_profiles_trigger ON public.profiles;
CREATE TRIGGER audit_profiles_trigger AFTER UPDATE OR DELETE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

DROP TRIGGER IF EXISTS audit_wallet_trigger ON public.wallet_transactions;
CREATE TRIGGER audit_wallet_trigger AFTER INSERT OR UPDATE OR DELETE ON public.wallet_transactions FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

DROP TRIGGER IF EXISTS audit_inventory_trigger ON public.fuel_inventory;
CREATE TRIGGER audit_inventory_trigger AFTER UPDATE ON public.fuel_inventory FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

-- ==========================================
-- 2. Enhanced RLS Policies (Admin & Driver)
-- ==========================================

-- Helper function to check if user is admin (Efficient caching)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Policies for Orders
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;
CREATE POLICY "Admins can manage all orders" ON public.orders FOR ALL USING (public.is_admin());

-- Update Policies for Profiles
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL USING (public.is_admin());

-- Update Policies for Inventory
DROP POLICY IF EXISTS "Admins can manage inventory" ON public.fuel_inventory;
CREATE POLICY "Admins can manage inventory" ON public.fuel_inventory FOR ALL USING (public.is_admin());
DROP POLICY IF EXISTS "Public can view inventory levels" ON public.fuel_inventory;
CREATE POLICY "Public can view inventory levels" ON public.fuel_inventory FOR SELECT USING (true);

-- Update Policies for Wallet
DROP POLICY IF EXISTS "Admins can view transactions" ON public.wallet_transactions;
CREATE POLICY "Admins can view transactions" ON public.wallet_transactions FOR SELECT USING (public.is_admin());

-- ==========================================
-- 3. Performance Indexing
-- ==========================================

-- Fast lookup for user order history
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON public.orders(user_id, status);

-- Fast lookup for driver assignments
CREATE INDEX IF NOT EXISTS idx_orders_driver ON public.orders(driver_id);

-- Speed up RLS policy checks
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Speed up vehicle lookups (e.g. during order creation)
CREATE INDEX IF NOT EXISTS idx_vehicles_license ON public.vehicles(license_plate);

-- Speed up notification polling/streams
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
