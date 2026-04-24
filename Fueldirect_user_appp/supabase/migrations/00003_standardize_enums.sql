-- 1. Create temporary types
CREATE TYPE public.order_status_new AS ENUM ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED');
CREATE TYPE public.payment_status_new AS ENUM ('PENDING', 'PAID', 'REFUNDED', 'FAILED');

-- 2. Drop defaults before altering types (Crucial fix)
ALTER TABLE public.orders ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.orders ALTER COLUMN payment_status DROP DEFAULT;
ALTER TABLE public.order_status_history ALTER COLUMN status DROP DEFAULT;

-- 3. Update the columns that use these types
ALTER TABLE public.orders 
  ALTER COLUMN status TYPE public.order_status_new 
  USING (upper(status::text)::public.order_status_new),
  ALTER COLUMN payment_status TYPE public.payment_status_new 
  USING (upper(payment_status::text)::public.payment_status_new);

ALTER TABLE public.order_status_history 
  ALTER COLUMN status TYPE public.order_status_new 
  USING (upper(status::text)::public.order_status_new);

-- 4. Drop old types and rename new ones
DROP TYPE public.order_status CASCADE;
DROP TYPE public.payment_status CASCADE;
ALTER TYPE public.order_status_new RENAME TO order_status;
ALTER TYPE public.payment_status_new RENAME TO payment_status;

-- 5. Re-apply new standardized defaults
ALTER TABLE public.orders ALTER COLUMN status SET DEFAULT 'PENDING'::public.order_status;
ALTER TABLE public.orders ALTER COLUMN payment_status SET DEFAULT 'PENDING'::public.payment_status;
