-- ============================================================
-- MULTI-BRANCH EXTENSION SCHEMA
-- Run this AFTER schema.sql
-- ============================================================

-- ============================================================
-- BRANCHES
-- ============================================================
CREATE TABLE IF NOT EXISTS branches (
  id           BIGSERIAL PRIMARY KEY,
  code         VARCHAR(30)  NOT NULL UNIQUE,
  name         VARCHAR(150) NOT NULL,
  address      TEXT,
  city         VARCHAR(80),
  phone        VARCHAR(30),
  email        VARCHAR(100),
  is_head_office BOOLEAN    DEFAULT FALSE,
  is_active    BOOLEAN      DEFAULT TRUE,
  created_at   TIMESTAMPTZ  DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX idx_branches_code ON branches(code);

INSERT INTO branches (code, name, is_head_office, is_active)
VALUES ('HO', 'Head Office', TRUE, TRUE)
ON CONFLICT (code) DO NOTHING;

CREATE TRIGGER trg_branches_updated_at
  BEFORE UPDATE ON branches
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- USER PROFILES (extends Supabase auth.users)
-- ============================================================
CREATE TYPE user_role_enum AS ENUM (
  'super_admin',
  'admin',
  'manager',
  'cashier',
  'stock_keeper',
  'accountant',
  'viewer'
);

CREATE TABLE IF NOT EXISTS user_profiles (
  id           UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  branch_id    BIGINT       NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  full_name    VARCHAR(150),
  role         user_role_enum NOT NULL DEFAULT 'cashier',
  phone        VARCHAR(30),
  avatar_url   TEXT,
  is_active    BOOLEAN      DEFAULT TRUE,
  last_login   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ  DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX idx_user_profiles_branch ON user_profiles(branch_id);
CREATE INDEX idx_user_profiles_role   ON user_profiles(role);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches      ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "user_read_own_profile"
  ON user_profiles FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "user_update_own_profile"
  ON user_profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- Admins can manage all profiles in their branch
CREATE POLICY "admin_manage_profiles"
  ON user_profiles FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role IN ('super_admin','admin')
    )
  );

-- All authenticated users can read branches
CREATE POLICY "read_branches"
  ON branches FOR SELECT TO authenticated USING (true);

-- Only super_admin can manage branches
CREATE POLICY "admin_manage_branches"
  ON branches FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'super_admin'
    )
  );

-- ============================================================
-- FUNCTION: get current user's branch id
-- ============================================================
CREATE OR REPLACE FUNCTION fn_my_branch_id()
RETURNS BIGINT LANGUAGE sql STABLE AS $$
  SELECT branch_id FROM user_profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- Add branch_id to all transaction tables
-- ============================================================
ALTER TABLE stocks          ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);
ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);
ALTER TABLE sales_orders    ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);
ALTER TABLE stock_transfers ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);
ALTER TABLE stock_adjustments ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);
ALTER TABLE expenses        ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES branches(id);

CREATE INDEX IF NOT EXISTS idx_stocks_branch    ON stocks(branch_id);
CREATE INDEX IF NOT EXISTS idx_po_branch        ON purchase_orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_so_branch        ON sales_orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_transfer_branch  ON stock_transfers(branch_id);
CREATE INDEX IF NOT EXISTS idx_adj_branch       ON stock_adjustments(branch_id);
CREATE INDEX IF NOT EXISTS idx_expenses_branch  ON expenses(branch_id);
