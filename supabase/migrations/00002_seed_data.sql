-- 00002_seed_data.sql
-- Description: Seeding initial fuel prices and inventory.

-- 1. Seed Fuel Prices
INSERT INTO public.fuel_prices (name, price, unit, icon_name)
VALUES 
('Petrol', 3.49, 'gal', 'local_gas_station'),
('Diesel', 3.32, 'gal', 'local_gas_station'),
('Premium', 3.75, 'gal', 'local_gas_station')
ON CONFLICT DO NOTHING;

-- 2. Seed Initial Fuel Inventory
INSERT INTO public.fuel_inventory (fuel_type, total_available, capacity)
VALUES 
('Petrol', 5000.00, 10000.00),
('Diesel', 5000.00, 10000.00),
('Premium', 3000.00, 5000.00)
ON CONFLICT DO NOTHING;

-- 3. Seed some default Coupons (Optional)
INSERT INTO public.coupons (code, discount_percentage, expiry_date, usage_limit, is_active)
VALUES 
('WELCOME10', 10.00, now() + interval '1 year', 1000, true),
('FUEL5', 5.00, now() + interval '6 months', 500, true)
ON CONFLICT (code) DO NOTHING;
