-- 0001_core_types.sql
-- Description: Core Enum types and extensions for the FuelDirect platform.

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User Roles
DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('admin', 'customer', 'driver');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Order Status (Synced with Flutter String Literals)
DO $$ BEGIN
    CREATE TYPE public.order_status AS ENUM (
        'PENDING', 
        'ASSIGNED', 
        'ON_THE_WAY', 
        'ARRIVED', 
        'DELIVERING', 
        'DELIVERED', 
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Payment Status
DO $$ BEGIN
    CREATE TYPE public.payment_status AS ENUM ('PENDING', 'PAID', 'REFUNDED', 'FAILED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Fuel Types
DO $$ BEGIN
    CREATE TYPE public.fuel_type AS ENUM ('Petrol', 'Diesel', 'Premium');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tanker Status
DO $$ BEGIN
    CREATE TYPE public.tanker_status AS ENUM ('Active', 'Maintenance', 'Offline');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Transaction Types
DO $$ BEGIN
    CREATE TYPE public.transaction_type AS ENUM ('PAYMENT', 'REFUND', 'TOPUP', 'WITHDRAWAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
