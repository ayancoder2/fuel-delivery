-- Description: Core schema setup for FuelDirect including profiles, assets, operations, and financials.

-- Cleanup existing relations (Optional but recommended for initial baseline)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.payment_methods CASCADE;
DROP TABLE IF EXISTS public.addresses CASCADE;
DROP TABLE IF EXISTS public.wallet_transactions CASCADE;
DROP TABLE IF EXISTS public.earnings CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.delivery_proofs CASCADE;
DROP TABLE IF EXISTS public.safety_checklists CASCADE;
DROP TABLE IF EXISTS public.order_status_history CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.driver_vehicles CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.vehicles CASCADE;
DROP TABLE IF EXISTS public.tankers CASCADE;
DROP TABLE IF EXISTS public.fuel_loads CASCADE;
DROP TABLE IF EXISTS public.fuel_prices CASCADE;
DROP TABLE IF EXISTS public.fuel_inventory CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.coupons CASCADE;

DROP TYPE IF EXISTS public.user_role CASCADE;
DROP TYPE IF EXISTS public.order_status CASCADE;
DROP TYPE IF EXISTS public.payment_status CASCADE;
DROP TYPE IF EXISTS public.fuel_type CASCADE;
DROP TYPE IF EXISTS public.tanker_status CASCADE;
DROP TYPE IF EXISTS public.maintenance_status CASCADE;
DROP TYPE IF EXISTS public.transaction_type CASCADE;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. Types and Enums
-- ==========================================

CREATE TYPE public.user_role AS ENUM ('admin', 'customer', 'driver');
CREATE TYPE public.order_status AS ENUM ('Pending', 'Assigned', 'In Progress', 'Completed', 'Cancelled', 'On The Way');
CREATE TYPE public.payment_status AS ENUM ('Pending', 'Paid', 'Refunded', 'Failed');
CREATE TYPE public.fuel_type AS ENUM ('Petrol', 'Diesel', 'Premium');
CREATE TYPE public.tanker_status AS ENUM ('Active', 'Maintenance', 'Offline');
CREATE TYPE public.maintenance_status AS ENUM ('Good', 'Due Soon', 'In Service');
CREATE TYPE public.transaction_type AS ENUM ('Payment', 'Refund', 'Wallet Topup', 'Wallet Withdrawal');

-- ==========================================
-- 2. Profiles (Extends Auth.Users)
-- ==========================================

CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text NOT NULL,
    email text UNIQUE NOT NULL,
    role public.user_role DEFAULT 'customer'::public.user_role,
    phone_number text,
    avatar_url text,
    wallet_balance numeric(12,2) DEFAULT 0.00,
    loyalty_points integer DEFAULT 0,
    subscription_plan text DEFAULT 'Free',
    fcm_token text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ==========================================
-- 3. Reference Tables
-- ==========================================

CREATE TABLE public.fuel_prices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL, -- e.g. "Petrol", "Diesel"
    price numeric(10,2) NOT NULL,
    unit text DEFAULT 'gal',
    icon_name text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.fuel_inventory (
    fuel_type public.fuel_type PRIMARY KEY,
    total_available numeric(12,2) DEFAULT 0.00,
    capacity numeric(12,2) DEFAULT 0.00,
    last_updated timestamptz DEFAULT now()
);

-- ==========================================
-- 4. Assets (Tankers & Vehicles)
-- ==========================================

CREATE TABLE public.tankers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tanker_id_label text UNIQUE NOT NULL,
    capacity numeric(12,2) NOT NULL,
    fuel_type public.fuel_type NOT NULL,
    region text,
    maintenance_status public.maintenance_status DEFAULT 'Good',
    current_status public.tanker_status DEFAULT 'Active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.vehicles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    license_plate text UNIQUE NOT NULL,
    fuel_type public.fuel_type NOT NULL,
    tank_capacity numeric(10,2) NOT NULL,
    make text,
    model text,
    year integer,
    color text,
    type text, -- e.g. Sedan, SUV
    owner_type text DEFAULT 'Individual' CHECK (owner_type IN ('Individual', 'Fleet')),
    status text DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ==========================================
-- 5. Personnel (Drivers)
-- ==========================================

CREATE TABLE public.drivers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'Offline' CHECK (status IN ('Online', 'Offline', 'Busy')),
    region text,
    rating numeric(3,2) DEFAULT 5.00,
    deliveries_count integer DEFAULT 0,
    compliance_status text DEFAULT 'Active' CHECK (compliance_status IN ('Active', 'Expiring', 'Inactive')),
    assigned_tanker_id uuid REFERENCES public.tankers(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Driver Vehicles (Personal or additional)
CREATE TABLE public.driver_vehicles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
    make text,
    model text,
    license_plate text,
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 6. Operations (Orders & Delivery)
-- ==========================================

CREATE TABLE public.orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number text UNIQUE NOT NULL,
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    vehicle_id uuid REFERENCES public.vehicles(id),
    driver_id uuid REFERENCES public.drivers(id),
    fuel_type public.fuel_type NOT NULL,
    quantity numeric(10,2) NOT NULL,
    total_price numeric(12,2) NOT NULL,
    status public.order_status DEFAULT 'Pending',
    payment_status public.payment_status DEFAULT 'Pending',
    delivery_address text NOT NULL,
    latitude double precision,
    longitude double precision,
    scheduled_time timestamptz,
    driver_latitude double precision,
    driver_longitude double precision,
    driver_name text, -- De-normalized for quick view
    driver_photo text,
    driver_vehicle text,
    eta text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.delivery_proofs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    photo_url text,
    proof_type text DEFAULT 'meter_reading',
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.safety_checklists (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    driver_id uuid NOT NULL REFERENCES public.drivers(id),
    is_parking_brake_set boolean DEFAULT false,
    is_engine_off boolean DEFAULT false,
    no_smoking_or_flames boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.order_status_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status public.order_status NOT NULL,
    reason text,
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 7. Accounting & Financials
-- ==========================================

CREATE TABLE public.transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number text UNIQUE NOT NULL,
    order_id uuid REFERENCES public.orders(id),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    amount numeric(12,2) NOT NULL,
    payment_method text DEFAULT 'Card' CHECK (payment_method IN ('Card', 'Wallet', 'Cash')),
    type public.transaction_type DEFAULT 'Payment',
    status text DEFAULT 'Pending' CHECK (status IN ('Success', 'Pending', 'Failed')),
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.wallet_transactions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    amount numeric(12,2) NOT NULL,
    type text NOT NULL, -- TOPUP, SPEND, REFUND
    description text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.earnings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid NOT NULL REFERENCES public.drivers(id),
    order_id uuid REFERENCES public.orders(id),
    amount numeric(12,2) NOT NULL,
    tip_amount numeric(10,2) DEFAULT 0.00,
    description text,
    status text DEFAULT 'pending',
    earned_at timestamptz DEFAULT now()
);

CREATE TABLE public.coupons (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    code text UNIQUE NOT NULL,
    discount_percentage numeric(5,2) DEFAULT 0.00,
    discount_amount numeric(10,2) DEFAULT 0.00,
    expiry_date timestamptz NOT NULL,
    usage_limit integer,
    usage_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 8. Customer Data
-- ==========================================

CREATE TABLE public.addresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title text NOT NULL, -- e.g. "Home", "Office"
    address text NOT NULL,
    is_default boolean DEFAULT false,
    latitude double precision,
    longitude double precision,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.payment_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    card_type text NOT NULL,
    last_4 text NOT NULL,
    expiry_date text NOT NULL,
    is_default boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.reviews (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    rating numeric(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    feedback text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title text,
    body text,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 9. Inventory Management
-- ==========================================

CREATE TABLE public.fuel_loads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    load_number text UNIQUE NOT NULL,
    fuel_type public.fuel_type NOT NULL,
    purchased_quantity numeric(12,2) NOT NULL,
    remaining_quantity numeric(12,2) NOT NULL,
    cost_per_gal numeric(10,2) NOT NULL,
    sell_price numeric(10,2) NOT NULL,
    status text DEFAULT 'Pending' CHECK (status IN ('Active', 'Reserve', 'Pending')),
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 10. Triggers and Automation
-- ==========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_tankers_updated_at BEFORE UPDATE ON public.tankers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_fuel_prices_updated_at BEFORE UPDATE ON public.fuel_prices FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function to handle new user registration from Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'New User'),
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'customer'::public.user_role)
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==========================================
-- 11. Row Level Security (RLS) - Basic Setup
-- ==========================================

-- ==========================================
-- 11. Row Level Security (RLS) - Comprehensive Setup
-- ==========================================

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Vehicles
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own vehicles." ON public.vehicles;
CREATE POLICY "Users can manage their own vehicles." ON public.vehicles FOR ALL USING (auth.uid() = user_id);

-- Orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own orders." ON public.orders;
CREATE POLICY "Users can view their own orders." ON public.orders FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own orders." ON public.orders;
CREATE POLICY "Users can create their own orders." ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Drivers can view assigned orders." ON public.orders;
CREATE POLICY "Drivers can view assigned orders." ON public.orders FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.drivers WHERE user_id = auth.uid() AND id = orders.driver_id)
);

-- Addresses
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own addresses." ON public.addresses;
CREATE POLICY "Users can manage their own addresses." ON public.addresses FOR ALL USING (auth.uid() = user_id);

-- Payment Methods
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own payment methods." ON public.payment_methods;
CREATE POLICY "Users can manage their own payment methods." ON public.payment_methods FOR ALL USING (auth.uid() = user_id);

-- Reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reviews are viewable by everyone." ON public.reviews;
CREATE POLICY "Reviews are viewable by everyone." ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create reviews for their orders." ON public.reviews;
CREATE POLICY "Users can create reviews for their orders." ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Drivers
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Driver profiles are viewable by everyone." ON public.drivers;
CREATE POLICY "Driver profiles are viewable by everyone." ON public.drivers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Drivers can update their own driver status." ON public.drivers;
CREATE POLICY "Drivers can update their own driver status." ON public.drivers FOR UPDATE USING (auth.uid() = user_id);

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own notifications." ON public.notifications;
CREATE POLICY "Users can view their own notifications." ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications (mark as read)." ON public.notifications;
CREATE POLICY "Users can update their own notifications (mark as read)." ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Transactions
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own wallet transactions." ON public.wallet_transactions;
CREATE POLICY "Users can view their own wallet transactions." ON public.wallet_transactions FOR SELECT USING (auth.uid() = user_id);
