-- 0004_order_operations.sql
-- Description: Core ordering and delivery tracking logic.

CREATE TABLE IF NOT EXISTS public.orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number text UNIQUE DEFAULT ('ORD-' || upper(substring(gen_random_uuid()::text from 1 for 8))),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    vehicle_id uuid REFERENCES public.vehicles(id),
    fuel_type public.fuel_type NOT NULL,
    quantity numeric(10,2) NOT NULL,
    total_price numeric(12,2) NOT NULL,
    status public.order_status DEFAULT 'PENDING',
    payment_status public.payment_status DEFAULT 'PENDING',
    delivery_address text NOT NULL,
    latitude double precision,
    longitude double precision,
    scheduled_time timestamptz,
    driver_latitude double precision,
    driver_longitude double precision,
    driver_name text,
    driver_photo text,
    driver_vehicle text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Order Status History for auditing
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status public.order_status NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own orders." ON public.orders;
CREATE POLICY "Users can view their own orders." ON public.orders FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own orders." ON public.orders;
CREATE POLICY "Users can create their own orders." ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
