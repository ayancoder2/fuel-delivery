-- 0006_inventory_prices.sql
-- Description: Fuel pricing and stock management.

-- Dynamic Fuel Prices
CREATE TABLE IF NOT EXISTS public.fuel_prices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL, -- "Petrol", "Diesel", "Premium"
    price numeric(10,2) NOT NULL,
    unit text DEFAULT 'gal',
    icon_name text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Real-time Stock Tracking
CREATE TABLE IF NOT EXISTS public.fuel_inventory (
    fuel_type public.fuel_type PRIMARY KEY,
    total_available numeric(12,2) DEFAULT 0.00,
    capacity numeric(12,2) DEFAULT 0.00,
    last_updated timestamptz DEFAULT now()
);

-- Seed Initial Prices & Inventory
INSERT INTO public.fuel_prices (name, price, unit, icon_name)
VALUES 
('Petrol', 3.49, 'gal', 'local_gas_station'),
('Diesel', 3.32, 'gal', 'local_gas_station'),
('Premium', 3.75, 'gal', 'local_gas_station')
ON CONFLICT DO NOTHING;

INSERT INTO public.fuel_inventory (fuel_type, total_available, capacity)
VALUES 
('Petrol', 5000.00, 10000.00),
('Diesel', 5000.00, 10000.00),
('Premium', 3000.00, 5000.00)
ON CONFLICT DO NOTHING;
