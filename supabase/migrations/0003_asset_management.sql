-- 0003_asset_management.sql
-- Description: Management of tankers and customer vehicles.

-- Tanker Fleet
CREATE TABLE IF NOT EXISTS public.tankers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tanker_id_label text UNIQUE NOT NULL,
    capacity numeric(12,2) NOT NULL,
    fuel_type public.fuel_type NOT NULL,
    region text,
    current_status public.tanker_status DEFAULT 'Active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Customer Vehicles
CREATE TABLE IF NOT EXISTS public.vehicles (
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
    status text DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own vehicles." ON public.vehicles;
CREATE POLICY "Users can manage their own vehicles." ON public.vehicles FOR ALL USING (auth.uid() = user_id);
