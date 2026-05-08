-- ============================================================
-- PosHub - Car Paint Materials Inventory Management System
-- Database: Supabase (PostgreSQL)
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- AUTO UPDATE TRIGGER FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 1. SUPPLIERS
-- ============================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id            BIGSERIAL PRIMARY KEY,
  code          VARCHAR(30)  UNIQUE,
  name          VARCHAR(150) NOT NULL,
  contact_person VARCHAR(100),
  phone         VARCHAR(30),
  email         VARCHAR(100),
  address       TEXT,
  city          VARCHAR(80),
  country       VARCHAR(80)  DEFAULT 'Bangladesh',
  credit_limit  NUMERIC(15,2) DEFAULT 0,
  balance       NUMERIC(15,2) DEFAULT 0,
  is_active     BOOLEAN      DEFAULT TRUE,
  notes         TEXT,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);
COMMENT ON TABLE suppliers IS 'Supplier / vendor master list';
CREATE INDEX idx_suppliers_name   ON suppliers(name);
CREATE INDEX idx_suppliers_phone  ON suppliers(phone);

CREATE TRIGGER trg_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 2. CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id          BIGSERIAL PRIMARY KEY,
  code        VARCHAR(30)  UNIQUE,
  name        VARCHAR(100) NOT NULL UNIQUE,
  parent_id   BIGINT       REFERENCES categories(id) ON DELETE SET NULL,
  description TEXT,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);
COMMENT ON TABLE categories IS 'Product category hierarchy';
CREATE INDEX idx_categories_name      ON categories(name);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 3. BRANDS
-- ============================================================
CREATE TABLE IF NOT EXISTS brands (
  id          BIGSERIAL PRIMARY KEY,
  code        VARCHAR(30)  UNIQUE,
  name        VARCHAR(100) NOT NULL UNIQUE,
  origin      VARCHAR(80),
  description TEXT,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);
COMMENT ON TABLE brands IS 'Product brand / manufacturer master';
CREATE INDEX idx_brands_name ON brands(name);

CREATE TRIGGER trg_brands_updated_at
  BEFORE UPDATE ON brands
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 4. UNITS OF MEASURE
-- ============================================================
CREATE TABLE IF NOT EXISTS units (
  id           BIGSERIAL PRIMARY KEY,
  code         VARCHAR(20)  NOT NULL UNIQUE,
  name         VARCHAR(60)  NOT NULL,
  base_unit_id BIGINT       REFERENCES units(id) ON DELETE SET NULL,
  conversion   NUMERIC(12,6) DEFAULT 1,
  is_active    BOOLEAN       DEFAULT TRUE,
  created_at   TIMESTAMPTZ   DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   DEFAULT NOW()
);
COMMENT ON TABLE units IS 'Units of measure with optional conversion factor';
INSERT INTO units (code, name) VALUES
  ('LTR',  'Litre'),
  ('KG',   'Kilogram'),
  ('PCS',  'Pieces'),
  ('GAL',  'Gallon'),
  ('TIN',  'Tin'),
  ('BOX',  'Box'),
  ('SET',  'Set'),
  ('ML',   'Millilitre'),
  ('GM',   'Gram')
ON CONFLICT (code) DO NOTHING;

CREATE TRIGGER trg_units_updated_at
  BEFORE UPDATE ON units
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 5. LOCATIONS / WAREHOUSES
-- ============================================================
CREATE TABLE IF NOT EXISTS locations (
  id          BIGSERIAL PRIMARY KEY,
  code        VARCHAR(30)  UNIQUE,
  name        VARCHAR(100) NOT NULL,
  address     TEXT,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);
COMMENT ON TABLE locations IS 'Warehouse / store locations';
INSERT INTO locations (code, name) VALUES ('MAIN', 'Main Warehouse')
ON CONFLICT (code) DO NOTHING;

CREATE TRIGGER trg_locations_updated_at
  BEFORE UPDATE ON locations
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 6. COLORS (car paint specific)
-- ============================================================
CREATE TABLE IF NOT EXISTS colors (
  id          BIGSERIAL PRIMARY KEY,
  code        VARCHAR(30)  UNIQUE,
  name        VARCHAR(80)  NOT NULL,
  hex_value   CHAR(7),
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);
COMMENT ON TABLE colors IS 'Paint color master — hex for UI display';
CREATE INDEX idx_colors_name ON colors(name);

-- ============================================================
-- 7. CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
  id             BIGSERIAL PRIMARY KEY,
  code           VARCHAR(30)  UNIQUE,
  name           VARCHAR(150) NOT NULL,
  contact_person VARCHAR(100),
  phone          VARCHAR(30),
  email          VARCHAR(100),
  address        TEXT,
  group_id       BIGINT,
  credit_limit   NUMERIC(15,2) DEFAULT 0,
  balance        NUMERIC(15,2) DEFAULT 0,
  is_active      BOOLEAN       DEFAULT TRUE,
  notes          TEXT,
  created_at     TIMESTAMPTZ   DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_customers_name  ON customers(name);
CREATE INDEX idx_customers_phone ON customers(phone);

CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 8. MAIN STOCKS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS stocks (
  id            BIGSERIAL PRIMARY KEY,

  -- Identity
  barcode       VARCHAR(60)   UNIQUE,
  name          VARCHAR(200)  NOT NULL,
  style_code    VARCHAR(60),

  -- Classification (FKs to master tables)
  brand_id      BIGINT        REFERENCES brands(id)     ON DELETE SET NULL,
  category_id   BIGINT        REFERENCES categories(id) ON DELETE SET NULL,
  color_id      BIGINT        REFERENCES colors(id)     ON DELETE SET NULL,
  unit_id       BIGINT        REFERENCES units(id)      ON DELETE SET NULL,
  location_id   BIGINT        REFERENCES locations(id)  ON DELETE SET NULL,
  supplier_id   BIGINT        REFERENCES suppliers(id)  ON DELETE SET NULL,

  -- Raw text fallbacks (for fast entry / import)
  brand         VARCHAR(100),
  category      VARCHAR(100),
  color         VARCHAR(80),
  size          VARCHAR(50),
  unit          VARCHAR(20),
  location      VARCHAR(80),
  supplier      VARCHAR(150),

  -- Batch / expiry
  batch_no      VARCHAR(60),
  expiry_date   DATE,

  -- ── Quantity Ledger ──────────────────────────────────────
  rcv_qty       NUMERIC(12,4) NOT NULL DEFAULT 0,  -- received / purchased
  trans_qty     NUMERIC(12,4) NOT NULL DEFAULT 0,  -- transferred out
  sale_qty      NUMERIC(12,4) NOT NULL DEFAULT 0,  -- sold
  conv_in       NUMERIC(12,4) NOT NULL DEFAULT 0,  -- conversion in
  conv_out      NUMERIC(12,4) NOT NULL DEFAULT 0,  -- conversion out
  damage_qty    NUMERIC(12,4) NOT NULL DEFAULT 0,  -- damaged / written-off
  return_qty    NUMERIC(12,4) NOT NULL DEFAULT 0,  -- customer returns back
  adj_qty       NUMERIC(12,4) NOT NULL DEFAULT 0,  -- manual adjustments (±)

  -- balance = rcv + return + conv_in + adj - sale - trans - conv_out - damage
  balance       NUMERIC(12,4) GENERATED ALWAYS AS (
                  rcv_qty + return_qty + conv_in + adj_qty
                  - sale_qty - trans_qty - conv_out - damage_qty
                ) STORED,

  -- ── Pricing ──────────────────────────────────────────────
  cpu           NUMERIC(12,2) NOT NULL DEFAULT 0,  -- cost price per unit
  mrp           NUMERIC(12,2) NOT NULL DEFAULT 0,  -- max retail price
  avg_cost      NUMERIC(12,4) NOT NULL DEFAULT 0,  -- weighted average cost

  -- ── Computed Financials (updated by trigger) ─────────────
  tot_cost_val  NUMERIC(15,2) NOT NULL DEFAULT 0,  -- balance * avg_cost
  tot_sale_val  NUMERIC(15,2) NOT NULL DEFAULT 0,  -- sale_qty * mrp
  profit        NUMERIC(15,2) NOT NULL DEFAULT 0,  -- tot_sale_val - (sale_qty * avg_cost)

  -- ── Reorder ──────────────────────────────────────────────
  min_stock     NUMERIC(12,4) NOT NULL DEFAULT 0,

  -- ── Flags ────────────────────────────────────────────────
  is_active     BOOLEAN       DEFAULT TRUE,
  notes         TEXT,

  created_at    TIMESTAMPTZ   DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   DEFAULT NOW(),

  -- Constraints
  CONSTRAINT chk_rcv_qty_nn    CHECK (rcv_qty    >= 0),
  CONSTRAINT chk_sale_qty_nn   CHECK (sale_qty   >= 0),
  CONSTRAINT chk_damage_qty_nn CHECK (damage_qty >= 0),
  CONSTRAINT chk_trans_qty_nn  CHECK (trans_qty  >= 0),
  CONSTRAINT chk_cpu_nn        CHECK (cpu        >= 0),
  CONSTRAINT chk_mrp_nn        CHECK (mrp        >= 0)
);

COMMENT ON COLUMN stocks.rcv_qty    IS 'Total quantity received from purchases';
COMMENT ON COLUMN stocks.trans_qty  IS 'Quantity transferred to other locations';
COMMENT ON COLUMN stocks.sale_qty   IS 'Total quantity sold';
COMMENT ON COLUMN stocks.conv_in    IS 'Quantity converted/received from conversion';
COMMENT ON COLUMN stocks.conv_out   IS 'Quantity converted out to another product';
COMMENT ON COLUMN stocks.damage_qty IS 'Quantity written off as damage/loss';
COMMENT ON COLUMN stocks.return_qty IS 'Quantity returned by customers';
COMMENT ON COLUMN stocks.adj_qty    IS 'Net manual stock adjustment (can be negative)';
COMMENT ON COLUMN stocks.balance    IS 'Auto-calculated: rcv+return+conv_in+adj-sale-trans-conv_out-damage';
COMMENT ON COLUMN stocks.cpu        IS 'Cost price per unit (latest purchase price)';
COMMENT ON COLUMN stocks.mrp        IS 'Maximum / selling retail price';
COMMENT ON COLUMN stocks.avg_cost   IS 'Weighted average cost per unit';
COMMENT ON COLUMN stocks.tot_cost_val IS 'balance × avg_cost';
COMMENT ON COLUMN stocks.tot_sale_val IS 'sale_qty × mrp';
COMMENT ON COLUMN stocks.profit       IS 'tot_sale_val - (sale_qty × avg_cost)';

-- Indexes
CREATE INDEX idx_stocks_barcode     ON stocks(barcode);
CREATE INDEX idx_stocks_name        ON stocks(name);
CREATE INDEX idx_stocks_category_id ON stocks(category_id);
CREATE INDEX idx_stocks_brand_id    ON stocks(brand_id);
CREATE INDEX idx_stocks_supplier_id ON stocks(supplier_id);
CREATE INDEX idx_stocks_category    ON stocks(category);
CREATE INDEX idx_stocks_brand       ON stocks(brand);
CREATE INDEX idx_stocks_supplier    ON stocks(supplier);
CREATE INDEX idx_stocks_balance     ON stocks(balance);
CREATE INDEX idx_stocks_expiry      ON stocks(expiry_date);

-- Auto updated_at
CREATE TRIGGER trg_stocks_updated_at
  BEFORE UPDATE ON stocks
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── Trigger: auto-recalculate financial columns on qty/price change ──
CREATE OR REPLACE FUNCTION fn_stocks_calc_financials()
RETURNS TRIGGER AS $$
BEGIN
  NEW.tot_cost_val := (
    NEW.rcv_qty + NEW.return_qty + NEW.conv_in + NEW.adj_qty
    - NEW.sale_qty - NEW.trans_qty - NEW.conv_out - NEW.damage_qty
  ) * NEW.avg_cost;

  NEW.tot_sale_val := NEW.sale_qty * NEW.mrp;
  NEW.profit       := NEW.tot_sale_val - (NEW.sale_qty * NEW.avg_cost);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stocks_financials
  BEFORE INSERT OR UPDATE ON stocks
  FOR EACH ROW EXECUTE FUNCTION fn_stocks_calc_financials();

-- ============================================================
-- 9. STOCK MOVEMENTS
-- ============================================================
CREATE TYPE movement_type_enum AS ENUM (
  'purchase',
  'sale',
  'transfer_in',
  'transfer_out',
  'conversion_in',
  'conversion_out',
  'adjustment',
  'damage',
  'return',
  'opening'
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id              BIGSERIAL PRIMARY KEY,
  stock_id        BIGINT        NOT NULL REFERENCES stocks(id)    ON DELETE RESTRICT,
  location_id     BIGINT        REFERENCES locations(id) ON DELETE SET NULL,
  movement_type   movement_type_enum NOT NULL,
  quantity        NUMERIC(12,4) NOT NULL,
  unit_cost       NUMERIC(12,2) DEFAULT 0,
  unit_price      NUMERIC(12,2) DEFAULT 0,
  reference_no    VARCHAR(80),
  reference_type  VARCHAR(40),   -- 'purchase_order','sale_order','transfer', etc.
  reference_id    BIGINT,        -- FK id of the source document
  batch_no        VARCHAR(60),
  notes           TEXT,
  created_by      UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ   DEFAULT NOW(),

  CONSTRAINT chk_movement_qty_nonzero CHECK (quantity <> 0)
);

COMMENT ON TABLE  stock_movements IS 'Full audit trail of every stock quantity change';
COMMENT ON COLUMN stock_movements.reference_type IS 'Source document type: purchase_order, sale_order, transfer, adjustment…';
COMMENT ON COLUMN stock_movements.reference_id   IS 'PK of the source document row';

CREATE INDEX idx_movements_stock_id      ON stock_movements(stock_id);
CREATE INDEX idx_movements_type          ON stock_movements(movement_type);
CREATE INDEX idx_movements_reference_no  ON stock_movements(reference_no);
CREATE INDEX idx_movements_created_at    ON stock_movements(created_at DESC);
CREATE INDEX idx_movements_reference     ON stock_movements(reference_type, reference_id);

-- ============================================================
-- 10. PURCHASE ORDERS
-- ============================================================
CREATE TYPE po_status_enum AS ENUM (
  'draft', 'pending', 'partial', 'received', 'cancelled'
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  id           BIGSERIAL PRIMARY KEY,
  po_number    VARCHAR(40)   UNIQUE NOT NULL,
  supplier_id  BIGINT        REFERENCES suppliers(id) ON DELETE RESTRICT,
  location_id  BIGINT        REFERENCES locations(id) ON DELETE SET NULL,
  order_date   DATE          DEFAULT CURRENT_DATE,
  expected_date DATE,
  status       po_status_enum DEFAULT 'draft',
  subtotal     NUMERIC(15,2) DEFAULT 0,
  discount     NUMERIC(15,2) DEFAULT 0,
  tax          NUMERIC(15,2) DEFAULT 0,
  grand_total  NUMERIC(15,2) DEFAULT 0,
  paid_amount  NUMERIC(15,2) DEFAULT 0,
  due_amount   NUMERIC(15,2) GENERATED ALWAYS AS (grand_total - paid_amount) STORED,
  notes        TEXT,
  created_by   UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ   DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_po_supplier   ON purchase_orders(supplier_id);
CREATE INDEX idx_po_status     ON purchase_orders(status);
CREATE INDEX idx_po_order_date ON purchase_orders(order_date DESC);

CREATE TRIGGER trg_po_updated_at
  BEFORE UPDATE ON purchase_orders
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 11. PURCHASE ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id          BIGSERIAL PRIMARY KEY,
  po_id       BIGINT        NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  stock_id    BIGINT        NOT NULL REFERENCES stocks(id)          ON DELETE RESTRICT,
  ordered_qty NUMERIC(12,4) NOT NULL DEFAULT 0,
  received_qty NUMERIC(12,4) NOT NULL DEFAULT 0,
  unit_cost   NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount    NUMERIC(12,2) DEFAULT 0,
  tax_pct     NUMERIC(5,2)  DEFAULT 0,
  line_total  NUMERIC(15,2) GENERATED ALWAYS AS (
                (ordered_qty * unit_cost) - discount
              ) STORED,
  batch_no    VARCHAR(60),
  expiry_date DATE,
  notes       TEXT
);
CREATE INDEX idx_poi_po_id    ON purchase_order_items(po_id);
CREATE INDEX idx_poi_stock_id ON purchase_order_items(stock_id);

-- ============================================================
-- 12. SALES ORDERS
-- ============================================================
CREATE TYPE so_status_enum AS ENUM (
  'draft', 'quotation', 'pending', 'partial', 'completed',
  'returned', 'cancelled'
);

CREATE TABLE IF NOT EXISTS sales_orders (
  id            BIGSERIAL PRIMARY KEY,
  invoice_no    VARCHAR(40)   UNIQUE NOT NULL,
  customer_id   BIGINT        REFERENCES customers(id) ON DELETE RESTRICT,
  location_id   BIGINT        REFERENCES locations(id) ON DELETE SET NULL,
  sale_date     DATE          DEFAULT CURRENT_DATE,
  due_date      DATE,
  status        so_status_enum DEFAULT 'draft',
  subtotal      NUMERIC(15,2) DEFAULT 0,
  discount      NUMERIC(15,2) DEFAULT 0,
  tax           NUMERIC(15,2) DEFAULT 0,
  grand_total   NUMERIC(15,2) DEFAULT 0,
  paid_amount   NUMERIC(15,2) DEFAULT 0,
  due_amount    NUMERIC(15,2) GENERATED ALWAYS AS (grand_total - paid_amount) STORED,
  payment_method VARCHAR(40),
  notes         TEXT,
  created_by    UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ   DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_so_customer  ON sales_orders(customer_id);
CREATE INDEX idx_so_status    ON sales_orders(status);
CREATE INDEX idx_so_sale_date ON sales_orders(sale_date DESC);

CREATE TRIGGER trg_so_updated_at
  BEFORE UPDATE ON sales_orders
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 13. SALES ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS sales_order_items (
  id          BIGSERIAL PRIMARY KEY,
  so_id       BIGINT        NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  stock_id    BIGINT        NOT NULL REFERENCES stocks(id)       ON DELETE RESTRICT,
  qty         NUMERIC(12,4) NOT NULL DEFAULT 0,
  unit_price  NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount    NUMERIC(12,2) DEFAULT 0,
  tax_pct     NUMERIC(5,2)  DEFAULT 0,
  line_total  NUMERIC(15,2) GENERATED ALWAYS AS (
                (qty * unit_price) - discount
              ) STORED,
  batch_no    VARCHAR(60),
  notes       TEXT
);
CREATE INDEX idx_soi_so_id    ON sales_order_items(so_id);
CREATE INDEX idx_soi_stock_id ON sales_order_items(stock_id);

-- ============================================================
-- 14. STOCK TRANSFERS
-- ============================================================
CREATE TYPE transfer_status_enum AS ENUM (
  'draft', 'in_transit', 'completed', 'cancelled'
);

CREATE TABLE IF NOT EXISTS stock_transfers (
  id             BIGSERIAL PRIMARY KEY,
  transfer_no    VARCHAR(40)   UNIQUE NOT NULL,
  from_location  BIGINT        NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
  to_location    BIGINT        NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
  transfer_date  DATE          DEFAULT CURRENT_DATE,
  status         transfer_status_enum DEFAULT 'draft',
  notes          TEXT,
  created_by     UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ   DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   DEFAULT NOW(),
  CONSTRAINT chk_transfer_locations CHECK (from_location <> to_location)
);
CREATE INDEX idx_transfer_from ON stock_transfers(from_location);
CREATE INDEX idx_transfer_to   ON stock_transfers(to_location);
CREATE INDEX idx_transfer_date ON stock_transfers(transfer_date DESC);

CREATE TRIGGER trg_transfers_updated_at
  BEFORE UPDATE ON stock_transfers
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TABLE IF NOT EXISTS stock_transfer_items (
  id           BIGSERIAL PRIMARY KEY,
  transfer_id  BIGINT        NOT NULL REFERENCES stock_transfers(id) ON DELETE CASCADE,
  stock_id     BIGINT        NOT NULL REFERENCES stocks(id)          ON DELETE RESTRICT,
  quantity     NUMERIC(12,4) NOT NULL CHECK (quantity > 0),
  notes        TEXT
);
CREATE INDEX idx_sti_transfer_id ON stock_transfer_items(transfer_id);
CREATE INDEX idx_sti_stock_id    ON stock_transfer_items(stock_id);

-- ============================================================
-- 15. STOCK ADJUSTMENTS
-- ============================================================
CREATE TYPE adjustment_status_enum AS ENUM ('draft', 'approved', 'rejected');

CREATE TABLE IF NOT EXISTS stock_adjustments (
  id           BIGSERIAL PRIMARY KEY,
  adj_no       VARCHAR(40)   UNIQUE NOT NULL,
  location_id  BIGINT        REFERENCES locations(id) ON DELETE SET NULL,
  adj_date     DATE          DEFAULT CURRENT_DATE,
  reason       VARCHAR(200),
  status       adjustment_status_enum DEFAULT 'draft',
  approved_by  UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  notes        TEXT,
  created_by   UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ   DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_adj_location ON stock_adjustments(location_id);
CREATE INDEX idx_adj_date     ON stock_adjustments(adj_date DESC);
CREATE INDEX idx_adj_status   ON stock_adjustments(status);

CREATE TRIGGER trg_adj_updated_at
  BEFORE UPDATE ON stock_adjustments
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TABLE IF NOT EXISTS stock_adjustment_items (
  id            BIGSERIAL PRIMARY KEY,
  adjustment_id BIGINT        NOT NULL REFERENCES stock_adjustments(id) ON DELETE CASCADE,
  stock_id      BIGINT        NOT NULL REFERENCES stocks(id)            ON DELETE RESTRICT,
  quantity      NUMERIC(12,4) NOT NULL,  -- can be negative (write-off)
  unit_cost     NUMERIC(12,2) DEFAULT 0,
  reason        VARCHAR(200),
  notes         TEXT
);
CREATE INDEX idx_adj_items_adj_id   ON stock_adjustment_items(adjustment_id);
CREATE INDEX idx_adj_items_stock_id ON stock_adjustment_items(stock_id);

-- ============================================================
-- 16. EXPENSES
-- ============================================================
CREATE TABLE IF NOT EXISTS expense_categories (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expenses (
  id           BIGSERIAL PRIMARY KEY,
  category_id  BIGINT        REFERENCES expense_categories(id) ON DELETE SET NULL,
  expense_date DATE          DEFAULT CURRENT_DATE,
  amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  description  VARCHAR(300),
  reference_no VARCHAR(60),
  paid_by      UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  notes        TEXT,
  created_at   TIMESTAMPTZ   DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_expenses_category ON expenses(category_id);
CREATE INDEX idx_expenses_date     ON expenses(expense_date DESC);

CREATE TRIGGER trg_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- 17. PAYMENT ACCOUNTS
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_accounts (
  id           BIGSERIAL PRIMARY KEY,
  code         VARCHAR(30)  UNIQUE,
  name         VARCHAR(100) NOT NULL,
  account_type VARCHAR(40)  DEFAULT 'cash', -- cash, bank, mobile_banking
  bank_name    VARCHAR(100),
  account_no   VARCHAR(60),
  branch       VARCHAR(80),
  balance      NUMERIC(15,2) DEFAULT 0,
  is_active    BOOLEAN       DEFAULT TRUE,
  notes        TEXT,
  created_at   TIMESTAMPTZ   DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   DEFAULT NOW()
);
CREATE TRIGGER trg_accounts_updated_at
  BEFORE UPDATE ON payment_accounts
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (enable for Supabase)
-- ============================================================
ALTER TABLE suppliers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands            ENABLE ROW LEVEL SECURITY;
ALTER TABLE units             ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE colors            ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE stocks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_adjustment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses          ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_accounts  ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users full access (customize per role later)
CREATE POLICY "authenticated_all" ON suppliers          FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON categories         FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON brands             FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON units              FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON locations          FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON colors             FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON customers          FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stocks             FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stock_movements    FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON purchase_orders    FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON purchase_order_items FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON sales_orders       FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON sales_order_items  FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stock_transfers    FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stock_transfer_items FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stock_adjustments  FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON stock_adjustment_items FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON expenses           FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON expense_categories FOR ALL TO authenticated USING (true);
CREATE POLICY "authenticated_all" ON payment_accounts   FOR ALL TO authenticated USING (true);

-- ============================================================
-- END OF SCHEMA
-- ============================================================
