-- 0005_financial_core.sql
-- Description: Financial tracking, wallets, and promotional systems.

-- Wallet History
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount numeric(12,2) NOT NULL,
    type public.transaction_type NOT NULL,
    description text,
    created_at timestamptz DEFAULT now()
);

-- Promotional Coupons
CREATE TABLE IF NOT EXISTS public.coupons (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text UNIQUE NOT NULL,
    discount_percentage numeric(5,2) DEFAULT 0.00,
    discount_amount numeric(10,2) DEFAULT 0.00,
    expiry_date timestamptz NOT NULL,
    usage_limit integer,
    usage_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- General Transactions (Link between orders and payments)
CREATE TABLE IF NOT EXISTS public.transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number text UNIQUE NOT NULL,
    order_id uuid REFERENCES public.orders(id),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    amount numeric(12,2) NOT NULL,
    payment_method text DEFAULT 'Card' CHECK (payment_method IN ('Card', 'Wallet', 'Cash')),
    type public.transaction_type DEFAULT 'PAYMENT',
    status text DEFAULT 'Pending' CHECK (status IN ('Success', 'Pending', 'Failed')),
    created_at timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own wallet history." ON public.wallet_transactions;
CREATE POLICY "Users can view own wallet history." ON public.wallet_transactions FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view active coupons." ON public.coupons;
CREATE POLICY "Public can view active coupons." ON public.coupons FOR SELECT USING (is_active = true);
