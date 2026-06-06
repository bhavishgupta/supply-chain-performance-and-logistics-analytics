"""
=============================================================================
SUPPLY CHAIN ANALYTICS: END-TO-END DATA ANALYST PORTFOLIO PROJECT
Dataset: DataCo Global Supply Chain Dataset
Author: Portfolio Project
=============================================================================
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────────────────────
# GLOBAL PLOT STYLE
# ─────────────────────────────────────────────────────────────
sns.set_theme(style='whitegrid', palette='muted', font_scale=1.1)
CHART_DIR = '/home/claude/supply_chain_project/charts'
FIG_SIZE   = (12, 6)

def save(fig, name):
    fig.savefig(f'{CHART_DIR}/{name}.png', dpi=150, bbox_inches='tight')
    plt.close(fig)
    print(f'  ✓ Saved: {name}.png')

# ─────────────────────────────────────────────────────────────
# PHASE 2 – LOAD & UNDERSTAND DATASET
# ─────────────────────────────────────────────────────────────
print("=" * 70)
print("PHASE 2 – DATASET UNDERSTANDING")
print("=" * 70)

df_raw = pd.read_csv(
    '/mnt/user-data/uploads/DataCoSupplyChainDataset.csv',
    encoding='latin1'
)

print(f"\nDataset Shape : {df_raw.shape[0]:,} rows × {df_raw.shape[1]} columns")
print(f"Memory Usage  : {df_raw.memory_usage(deep=True).sum() / 1e6:.1f} MB")

# ─────────────────────────────────────────────────────────────
# PHASE 3 – DATA QUALITY ASSESSMENT
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("PHASE 3 – DATA QUALITY REPORT")
print("=" * 70)

missing = df_raw.isnull().sum()
missing = missing[missing > 0]
print("\n[Missing Values]")
for col, cnt in missing.items():
    pct = cnt / len(df_raw) * 100
    print(f"  {col:<35} {cnt:>7,} ({pct:5.1f}%)")

print(f"\n[Duplicate Rows]: {df_raw.duplicated().sum():,}")
print(f"[Unique Orders]  : {df_raw['Order Id'].nunique():,}")
print(f"[Unique Customers]: {df_raw['Customer Id'].nunique():,}")

neg_profit = (df_raw['Order Profit Per Order'] < 0).sum()
print(f"\n[Negative Profit Orders]: {neg_profit:,} ({neg_profit/len(df_raw)*100:.1f}%)")

# Check: Customer Email & Password – single unique value = PII placeholder
print(f"\n[Customer Email unique values]: {df_raw['Customer Email'].nunique()}")
print(f"[Customer Password unique values]: {df_raw['Customer Password'].nunique()}")
print(f"[Product Description unique values]: {df_raw['Product Description'].nunique()}")
print(f"[Product Status unique values]: {df_raw['Product Status'].nunique()}")

# ─────────────────────────────────────────────────────────────
# PHASE 4 – DATA CLEANING
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("PHASE 4 – DATA CLEANING")
print("=" * 70)

df = df_raw.copy()

# 4.1 Drop columns that are useless, PII-sensitive, or entirely null
cols_to_drop = [
    'Customer Email',        # single value – anonymized placeholder
    'Customer Password',     # single value – security risk, no analytical value
    'Product Description',   # 100% null
    'Product Image',         # URL links – no analytical value
    'Product Status',        # only one value (0) – zero variance
]
df.drop(columns=cols_to_drop, inplace=True)
print(f"\n[4.1] Dropped {len(cols_to_drop)} useless/PII columns → {df.shape[1]} columns remaining")

# 4.2 Fix Date Columns
df['order_date']    = pd.to_datetime(df['order date (DateOrders)'],    format='%m/%d/%Y %H:%M', errors='coerce')
df['shipping_date'] = pd.to_datetime(df['shipping date (DateOrders)'], format='%m/%d/%Y %H:%M', errors='coerce')
df.drop(columns=['order date (DateOrders)', 'shipping date (DateOrders)'], inplace=True)
print(f"[4.2] Parsed date columns → {df['order_date'].isna().sum()} failed parses")

# 4.3 Handle Missing Values
#   - Customer Lname: 8 missing → fill with 'Unknown'
df['Customer Lname'].fillna('Unknown', inplace=True)
#   - Customer Zipcode: 3 missing → fill with 0 (non-critical)
df['Customer Zipcode'].fillna(0, inplace=True)
#   - Order Zipcode: 86.2% missing → drop column (not analytically useful)
df.drop(columns=['Order Zipcode'], inplace=True)
print(f"[4.3] Missing values handled. Remaining nulls: {df.isnull().sum().sum()}")

# 4.4 Standardize text columns
text_cols = ['Delivery Status', 'Shipping Mode', 'Market', 'Customer Segment',
             'Order Status', 'Category Name', 'Department Name', 'Order Region']
for col in text_cols:
    df[col] = df[col].str.strip().str.title()
print(f"[4.4] Standardized {len(text_cols)} text columns (strip + title case)")

# 4.5 Rename columns for Python friendliness
df.rename(columns={
    'Days for shipping (real)':      'actual_shipping_days',
    'Days for shipment (scheduled)': 'scheduled_shipping_days',
    'Benefit per order':             'benefit_per_order',
    'Sales per customer':            'sales_per_customer',
    'Delivery Status':               'delivery_status',
    'Late_delivery_risk':            'late_delivery_risk',
    'Category Id':                   'category_id',
    'Category Name':                 'category_name',
    'Customer City':                 'customer_city',
    'Customer Country':              'customer_country',
    'Customer Fname':                'customer_fname',
    'Customer Id':                   'customer_id',
    'Customer Lname':                'customer_lname',
    'Customer Segment':              'customer_segment',
    'Customer State':                'customer_state',
    'Customer Street':               'customer_street',
    'Customer Zipcode':              'customer_zipcode',
    'Department Id':                 'department_id',
    'Department Name':               'department_name',
    'Latitude':                      'latitude',
    'Longitude':                     'longitude',
    'Market':                        'market',
    'Order City':                    'order_city',
    'Order Country':                 'order_country',
    'Order Customer Id':             'order_customer_id',
    'Order Id':                      'order_id',
    'Order Item Cardprod Id':        'product_card_id',
    'Order Item Discount':           'order_item_discount',
    'Order Item Discount Rate':      'discount_rate',
    'Order Item Id':                 'order_item_id',
    'Order Item Product Price':      'item_product_price',
    'Order Item Profit Ratio':       'item_profit_ratio',
    'Order Item Quantity':           'order_quantity',
    'Sales':                         'sales',
    'Order Item Total':              'order_item_total',
    'Order Profit Per Order':        'profit_per_order',
    'Order Region':                  'order_region',
    'Order State':                   'order_state',
    'Order Status':                  'order_status',
    'Product Card Id':               'product_id',
    'Product Category Id':           'product_category_id',
    'Product Name':                  'product_name',
    'Product Price':                 'product_price',
    'Shipping Mode':                 'shipping_mode',
    'Type':                          'payment_type',
}, inplace=True)

print(f"[4.5] Columns renamed for Python friendliness")

print(f"\n✓ Clean dataset shape: {df.shape[0]:,} rows × {df.shape[1]} columns")

# ─────────────────────────────────────────────────────────────
# PHASE 5 – FEATURE ENGINEERING
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("PHASE 5 – FEATURE ENGINEERING")
print("=" * 70)

# 5.1 Delivery Delay (days)
df['delivery_delay_days'] = df['actual_shipping_days'] - df['scheduled_shipping_days']
# Positive = late, 0 = on time, negative = early

# 5.2 Late Delivery Flag (binary)
df['is_late_delivery'] = (df['delivery_delay_days'] > 0).astype(int)

# 5.3 Profit Margin %
df['profit_margin_pct'] = (df['profit_per_order'] / df['sales'].replace(0, np.nan)) * 100
df['profit_margin_pct'] = df['profit_margin_pct'].clip(-500, 500)  # cap extremes

# 5.4 High Value Order Flag
hv_threshold = df['order_item_total'].quantile(0.75)
df['is_high_value'] = (df['order_item_total'] >= hv_threshold).astype(int)

# 5.5 Date-based features
df['order_year']    = df['order_date'].dt.year
df['order_month']   = df['order_date'].dt.month
df['order_quarter'] = df['order_date'].dt.quarter
df['order_dayofweek'] = df['order_date'].dt.dayofweek  # 0=Mon

# 5.6 Discount Band
df['discount_band'] = pd.cut(
    df['discount_rate'],
    bins=[-0.01, 0.0, 0.1, 0.2, 0.3, 1.01],
    labels=['No Discount', 'Low (1-10%)', 'Medium (11-20%)', 'High (21-30%)', 'Very High (>30%)']
)

# 5.7 Shipping Speed Category
df['shipping_speed'] = df['actual_shipping_days'].apply(
    lambda x: 'Express (1-2d)' if x <= 2 else ('Standard (3-4d)' if x <= 4 else 'Slow (5+d)')
)

# 5.8 Risk Category (combining late delivery risk + fraud status)
def risk_category(row):
    if row['order_status'] == 'Suspected_Fraud':
        return 'High Risk'
    elif row['late_delivery_risk'] == 1:
        return 'Medium Risk'
    else:
        return 'Low Risk'

df['risk_category'] = df.apply(risk_category, axis=1)

# 5.9 Revenue per Unit
df['revenue_per_unit'] = df['sales'] / df['order_quantity'].replace(0, np.nan)

print("Features created:")
new_features = ['delivery_delay_days','is_late_delivery','profit_margin_pct',
                'is_high_value','order_year','order_month','order_quarter',
                'order_dayofweek','discount_band','shipping_speed','risk_category','revenue_per_unit']
for f in new_features:
    print(f"  ✓ {f}")

print(f"\n✓ Final dataset: {df.shape[0]:,} rows × {df.shape[1]} columns")

# Save cleaned dataset
df.to_csv('/home/claude/supply_chain_project/supply_chain_clean.csv', index=False)
print("✓ Cleaned dataset saved: supply_chain_clean.csv")

# ─────────────────────────────────────────────────────────────
# PHASE 6 – EDA VISUALIZATIONS
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("PHASE 6 – EXPLORATORY DATA ANALYSIS (15+ Charts)")
print("=" * 70)

PALETTE = 'Set2'

# ── Chart 1: Sales by Market ──────────────────────────────────
print("\nGenerating charts...")
fig, ax = plt.subplots(figsize=FIG_SIZE)
market_sales = df.groupby('market')['sales'].sum().sort_values(ascending=False)
bars = ax.bar(market_sales.index, market_sales.values / 1e6, color=sns.color_palette(PALETTE, len(market_sales)))
ax.set_title('Total Sales by Market (USD Millions)', fontweight='bold', fontsize=14)
ax.set_xlabel('Market'); ax.set_ylabel('Sales ($ Millions)')
for bar, val in zip(bars, market_sales.values / 1e6):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, f'${val:.1f}M', ha='center', fontsize=10)
save(fig, 'ch01_sales_by_market')

# ── Chart 2: Profit by Market ─────────────────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
market_profit = df.groupby('market')['profit_per_order'].sum().sort_values(ascending=False)
colors = ['#2ecc71' if v >= 0 else '#e74c3c' for v in market_profit.values]
bars = ax.bar(market_profit.index, market_profit.values / 1e6, color=colors)
ax.set_title('Total Profit by Market (USD Millions)', fontweight='bold', fontsize=14)
ax.set_xlabel('Market'); ax.set_ylabel('Profit ($ Millions)')
for bar, val in zip(bars, market_profit.values / 1e6):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02, f'${val:.1f}M', ha='center', fontsize=10)
save(fig, 'ch02_profit_by_market')

# ── Chart 3: Late Delivery Rate by Shipping Mode ──────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
late_by_mode = df.groupby('shipping_mode')['is_late_delivery'].mean().sort_values(ascending=False) * 100
bars = ax.bar(late_by_mode.index, late_by_mode.values, color=sns.color_palette('Reds_r', len(late_by_mode)))
ax.set_title('Late Delivery Rate by Shipping Mode (%)', fontweight='bold', fontsize=14)
ax.set_xlabel('Shipping Mode'); ax.set_ylabel('Late Delivery Rate (%)')
ax.set_ylim(0, 100)
for bar, val in zip(bars, late_by_mode.values):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, f'{val:.1f}%', ha='center', fontsize=11)
save(fig, 'ch03_late_delivery_by_shipping_mode')

# ── Chart 4: Sales Trend Over Time ───────────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
monthly_sales = df.groupby(['order_year','order_month'])['sales'].sum().reset_index()
monthly_sales['period'] = pd.to_datetime(
    monthly_sales['order_year'].astype(str) + '-' + monthly_sales['order_month'].astype(str).str.zfill(2))
monthly_sales = monthly_sales.sort_values('period')
ax.plot(monthly_sales['period'], monthly_sales['sales'] / 1e6, marker='o', linewidth=2, color='#2980b9')
ax.fill_between(monthly_sales['period'], monthly_sales['sales'] / 1e6, alpha=0.15, color='#2980b9')
ax.set_title('Monthly Sales Trend (USD Millions)', fontweight='bold', fontsize=14)
ax.set_xlabel('Date'); ax.set_ylabel('Sales ($ Millions)')
plt.xticks(rotation=45)
save(fig, 'ch04_monthly_sales_trend')

# ── Chart 5: Delivery Status Distribution ────────────────────
fig, axes = plt.subplots(1, 2, figsize=FIG_SIZE)
delivery_counts = df['delivery_status'].value_counts()
axes[0].pie(delivery_counts.values, labels=delivery_counts.index,
            autopct='%1.1f%%', startangle=90, colors=sns.color_palette('Set2'))
axes[0].set_title('Delivery Status Distribution', fontweight='bold')
delivery_by_mode = df.groupby(['shipping_mode','delivery_status']).size().unstack(fill_value=0)
delivery_by_mode.plot(kind='bar', ax=axes[1], colormap='Set2', edgecolor='white')
axes[1].set_title('Delivery Status by Shipping Mode', fontweight='bold')
axes[1].set_xlabel(''); axes[1].tick_params(axis='x', rotation=30)
axes[1].legend(loc='upper right', fontsize=8)
plt.tight_layout()
save(fig, 'ch05_delivery_status_distribution')

# ── Chart 6: Top 10 Products by Revenue ──────────────────────
fig, ax = plt.subplots(figsize=(12, 7))
top_products = df.groupby('product_name')['sales'].sum().sort_values(ascending=False).head(10)
colors = sns.color_palette('Blues_r', 10)
bars = ax.barh(top_products.index[::-1], top_products.values[::-1] / 1e6, color=colors)
ax.set_title('Top 10 Products by Total Revenue (USD Millions)', fontweight='bold', fontsize=14)
ax.set_xlabel('Revenue ($ Millions)')
for bar, val in zip(bars, top_products.values[::-1] / 1e6):
    ax.text(bar.get_width() + 0.02, bar.get_y() + bar.get_height()/2,
            f'${val:.1f}M', va='center', fontsize=9)
save(fig, 'ch06_top10_products_revenue')

# ── Chart 7: Customer Segment Analysis ───────────────────────
fig, axes = plt.subplots(1, 3, figsize=(14, 5))
metrics = ['sales', 'profit_per_order', 'order_item_total']
titles  = ['Avg Sales by Segment', 'Avg Profit by Segment', 'Avg Order Value by Segment']
for ax, metric, title in zip(axes, metrics, titles):
    seg_data = df.groupby('customer_segment')[metric].mean().sort_values(ascending=False)
    ax.bar(seg_data.index, seg_data.values, color=sns.color_palette('Set3', 3))
    ax.set_title(title, fontweight='bold', fontsize=11)
    ax.set_xlabel(''); ax.tick_params(axis='x', rotation=20)
plt.suptitle('Customer Segment Performance', fontweight='bold', fontsize=14, y=1.02)
plt.tight_layout()
save(fig, 'ch07_customer_segment_analysis')

# ── Chart 8: Order Status Distribution ───────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
status_counts = df['order_status'].value_counts()
colors_bar = sns.color_palette('RdYlGn', len(status_counts))
bars = ax.bar(status_counts.index, status_counts.values, color=colors_bar)
ax.set_title('Order Status Distribution', fontweight='bold', fontsize=14)
ax.set_xlabel('Order Status'); ax.set_ylabel('Number of Orders')
plt.xticks(rotation=30, ha='right')
for bar, val in zip(bars, status_counts.values):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 200,
            f'{val:,}', ha='center', fontsize=9)
save(fig, 'ch08_order_status_distribution')

# ── Chart 9: Profit Margin by Category (Top 15) ──────────────
fig, ax = plt.subplots(figsize=(12, 7))
cat_margin = df.groupby('category_name')['profit_margin_pct'].mean().sort_values(ascending=False).head(15)
colors_cat = ['#2ecc71' if v >= 0 else '#e74c3c' for v in cat_margin.values]
bars = ax.barh(cat_margin.index[::-1], cat_margin.values[::-1], color=colors_cat[::-1])
ax.set_title('Average Profit Margin % by Product Category (Top 15)', fontweight='bold', fontsize=14)
ax.set_xlabel('Avg Profit Margin (%)')
ax.axvline(0, color='black', linewidth=0.8, linestyle='--')
save(fig, 'ch09_profit_margin_by_category')

# ── Chart 10: Discount Rate vs Profit Relationship ────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
sample = df.sample(5000, random_state=42)
scatter = ax.scatter(sample['discount_rate'], sample['profit_per_order'],
                     alpha=0.3, c=sample['sales'], cmap='viridis', s=20)
plt.colorbar(scatter, ax=ax, label='Sales ($)')
ax.set_title('Discount Rate vs. Profit per Order', fontweight='bold', fontsize=14)
ax.set_xlabel('Discount Rate'); ax.set_ylabel('Profit per Order ($)')
ax.axhline(0, color='red', linewidth=1, linestyle='--', alpha=0.7)
save(fig, 'ch10_discount_vs_profit')

# ── Chart 11: Shipping Mode Mix ───────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=FIG_SIZE)
ship_rev = df.groupby('shipping_mode')['sales'].sum()
ship_cnt = df.groupby('shipping_mode').size()
axes[0].pie(ship_rev.values, labels=ship_rev.index, autopct='%1.1f%%',
            startangle=90, colors=sns.color_palette('Pastel1'))
axes[0].set_title('Revenue Share by Shipping Mode', fontweight='bold')
axes[1].pie(ship_cnt.values, labels=ship_cnt.index, autopct='%1.1f%%',
            startangle=90, colors=sns.color_palette('Pastel2'))
axes[1].set_title('Order Count Share by Shipping Mode', fontweight='bold')
plt.tight_layout()
save(fig, 'ch11_shipping_mode_mix')

# ── Chart 12: Regional Heatmap (Orders) ───────────────────────
fig, ax = plt.subplots(figsize=(14, 7))
region_cat = df.groupby(['order_region','customer_segment'])['sales'].sum().unstack(fill_value=0)
region_cat_norm = region_cat.div(region_cat.sum(axis=1), axis=0) * 100
sns.heatmap(region_cat_norm, annot=True, fmt='.1f', cmap='YlOrRd', ax=ax,
            linewidths=0.5, cbar_kws={'label': '% of Regional Revenue'})
ax.set_title('Revenue Contribution (%) by Region and Customer Segment', fontweight='bold', fontsize=14)
plt.yticks(rotation=0); plt.xticks(rotation=15)
plt.tight_layout()
save(fig, 'ch12_region_segment_heatmap')

# ── Chart 13: Delivery Delay Distribution ─────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
delay_counts = df['delivery_delay_days'].value_counts().sort_index()
colors_d = ['#2ecc71' if x <= 0 else '#e74c3c' for x in delay_counts.index]
ax.bar(delay_counts.index.astype(str), delay_counts.values, color=colors_d)
ax.set_title('Distribution of Delivery Delay Days\n(Negative = Early, 0 = On Time, Positive = Late)',
             fontweight='bold', fontsize=14)
ax.set_xlabel('Delay (days)'); ax.set_ylabel('Number of Orders')
save(fig, 'ch13_delivery_delay_distribution')

# ── Chart 14: Monthly Profit Trend ────────────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
monthly_profit = df.groupby(['order_year','order_month'])['profit_per_order'].sum().reset_index()
monthly_profit['period'] = pd.to_datetime(
    monthly_profit['order_year'].astype(str) + '-' + monthly_profit['order_month'].astype(str).str.zfill(2))
monthly_profit = monthly_profit.sort_values('period')
colors_mp = ['#2ecc71' if v >= 0 else '#e74c3c' for v in monthly_profit['profit_per_order']]
ax.bar(monthly_profit['period'].astype(str), monthly_profit['profit_per_order'] / 1e6, color=colors_mp)
ax.set_title('Monthly Profit Trend (USD Millions)', fontweight='bold', fontsize=14)
ax.set_xlabel('Month'); ax.set_ylabel('Profit ($ Millions)')
ax.axhline(0, color='black', linewidth=0.8, linestyle='--')
plt.xticks(rotation=45, ha='right', fontsize=7)
save(fig, 'ch14_monthly_profit_trend')

# ── Chart 15: Payment Type Analysis ──────────────────────────
fig, axes = plt.subplots(1, 2, figsize=FIG_SIZE)
pay_sales = df.groupby('payment_type')['sales'].sum()
pay_fraud = df[df['order_status'] == 'Suspected_Fraud'].groupby('payment_type').size()
axes[0].bar(pay_sales.index, pay_sales.values / 1e6, color=sns.color_palette('Set1', 4))
axes[0].set_title('Revenue by Payment Type', fontweight='bold')
axes[0].set_ylabel('Revenue ($ Millions)')
if len(pay_fraud) > 0:
    axes[1].bar(pay_fraud.index, pay_fraud.values, color=sns.color_palette('Reds', 4))
    axes[1].set_title('Suspected Fraud Count by Payment Type', fontweight='bold')
    axes[1].set_ylabel('Fraud Count')
plt.tight_layout()
save(fig, 'ch15_payment_type_analysis')

# ── Chart 16: Quarterly Performance ──────────────────────────
fig, axes = plt.subplots(1, 2, figsize=FIG_SIZE)
q_sales  = df.groupby(['order_year','order_quarter'])['sales'].sum().unstack()
q_profit = df.groupby(['order_year','order_quarter'])['profit_per_order'].sum().unstack()
q_sales.plot(kind='bar', ax=axes[0], colormap='Blues', edgecolor='white')
axes[0].set_title('Quarterly Sales by Year', fontweight='bold')
axes[0].set_xlabel('Year'); axes[0].tick_params(axis='x', rotation=0)
axes[0].set_ylabel('Sales ($)')
q_profit.plot(kind='bar', ax=axes[1], colormap='Greens', edgecolor='white')
axes[1].set_title('Quarterly Profit by Year', fontweight='bold')
axes[1].set_xlabel('Year'); axes[1].tick_params(axis='x', rotation=0)
axes[1].set_ylabel('Profit ($)')
plt.tight_layout()
save(fig, 'ch16_quarterly_performance')

# ── Chart 17: Top 10 Regions by Sales ────────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
region_sales = df.groupby('order_region')['sales'].sum().sort_values(ascending=False).head(10)
bars = ax.barh(region_sales.index[::-1], region_sales.values[::-1] / 1e6,
               color=sns.color_palette('Blues_r', 10))
ax.set_title('Top 10 Order Regions by Revenue', fontweight='bold', fontsize=14)
ax.set_xlabel('Revenue ($ Millions)')
save(fig, 'ch17_top10_regions')

# ── Chart 18: Profit Ratio Box Plot by Segment ───────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
df.boxplot(column='item_profit_ratio', by='customer_segment', ax=ax,
           patch_artist=True, showfliers=False)
ax.set_title('Item Profit Ratio Distribution by Customer Segment', fontweight='bold', fontsize=14)
ax.set_xlabel('Customer Segment'); ax.set_ylabel('Item Profit Ratio')
plt.suptitle('')
save(fig, 'ch18_profit_ratio_by_segment')

# ── Chart 19: Order Quantity Distribution ─────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
qty_data = df['order_quantity'].value_counts().sort_index()
ax.bar(qty_data.index.astype(str), qty_data.values, color=sns.color_palette('Spectral', len(qty_data)))
ax.set_title('Order Quantity Distribution', fontweight='bold', fontsize=14)
ax.set_xlabel('Order Quantity'); ax.set_ylabel('Number of Records')
for i, (x, y) in enumerate(zip(qty_data.index, qty_data.values)):
    ax.text(i, y + 200, f'{y/len(df)*100:.1f}%', ha='center', fontsize=10)
save(fig, 'ch19_order_quantity_distribution')

# ── Chart 20: Risk Category Breakdown ────────────────────────
fig, ax = plt.subplots(figsize=FIG_SIZE)
risk_data = df.groupby(['risk_category','shipping_mode']).size().unstack(fill_value=0)
risk_data.plot(kind='bar', ax=ax, colormap='RdYlGn_r', edgecolor='white')
ax.set_title('Risk Category vs Shipping Mode', fontweight='bold', fontsize=14)
ax.set_xlabel('Risk Category'); ax.set_ylabel('Number of Orders')
ax.tick_params(axis='x', rotation=0)
ax.legend(title='Shipping Mode', bbox_to_anchor=(1.05, 1))
plt.tight_layout()
save(fig, 'ch20_risk_category_shipping_mode')

print("\n✓ All 20 charts generated successfully!")

# ─────────────────────────────────────────────────────────────
# KPI SUMMARY TABLE
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("PHASE 10 – KEY PERFORMANCE INDICATORS")
print("=" * 70)

total_orders     = df['order_id'].nunique()
total_sales      = df['sales'].sum()
total_profit     = df['profit_per_order'].sum()
overall_margin   = (total_profit / total_sales) * 100
late_del_rate    = df['is_late_delivery'].mean() * 100
avg_ship_days    = df['actual_shipping_days'].mean()
fraud_rate       = (df['order_status'] == 'Suspected_Fraud').mean() * 100
total_customers  = df['customer_id'].nunique()
avg_order_value  = df['order_item_total'].mean()

print(f"""
┌─────────────────────────────────────────────────────┐
│              EXECUTIVE KPI DASHBOARD                │
├──────────────────────────────────┬──────────────────┤
│ Total Orders                     │ {total_orders:>14,} │
│ Total Revenue                    │ ${total_sales:>13,.0f} │
│ Total Profit                     │ ${total_profit:>13,.0f} │
│ Overall Profit Margin            │ {overall_margin:>13.1f}% │
│ Late Delivery Rate               │ {late_del_rate:>13.1f}% │
│ Average Shipping Days            │ {avg_ship_days:>13.1f}d │
│ Suspected Fraud Rate             │ {fraud_rate:>13.2f}% │
│ Total Unique Customers           │ {total_customers:>14,} │
│ Avg Order Item Value             │ ${avg_order_value:>13.2f} │
└──────────────────────────────────┴──────────────────┘
""")

print("✅ Analysis complete. Cleaned CSV and 20 charts saved.")
