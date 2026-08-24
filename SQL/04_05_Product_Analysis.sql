/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_05_Product_Analysis.sql
  Section: Product Popularity and Revenue Performance
==============================================================

Purpose:
Evaluate product sales performance among United States customers
by comparing sales volume, revenue, and product characteristics
within comparable product subcategories.

Analysis Scope:
- Q7: Top-selling products within each product subcategory
- Q7.1: Revenue performance of top-selling products
- Q8: Detailed profile of top-selling products

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql
- 04_01_Dataset_Exploration.sql
- 04_02_Time_Analysis.sql
- 04_03_Customer_Analysis.sql
- 04_04_Store_Analysis.sql

Important:
- The analysis includes only customers located in the
  United States.
- Product popularity is measured primarily by total quantity sold.
- Products are ranked within their own product subcategories.
- Revenue and average revenue per unit are used as supporting
  performance measures.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q7. Top-Selling Products by Subcategory
  --------------------------------------------------------------
  Business Question:
  Which products generated the highest sales volume within each
  product subcategory among United States customers?

  Objective:
  Rank products within comparable subcategories by total quantity
  sold and identify the sales-volume leaders.

  Popularity Definition:
  Product popularity is represented by total quantity sold
  within each product subcategory.
==============================================================*/

-- Calculate customer reach, order frequency, and sales volume
-- for products purchased by United States customers.
;with USProductSales as
(
    select
        s.ProductKey,
        p.SubCategoryKey,
        count(distinct s.CustomerKey) as DistinctCustomers,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold
    from dbo.HMSales as s
    inner join dbo.HMCustomers as c
        on s.CustomerKey = c.CustomerKey
    inner join dbo.HMProducts as p
        on s.ProductKey = p.ProductKey
    where c.Country = 'United States'
    group by
        s.ProductKey,
        p.SubCategoryKey
),

-- Rank products by sales volume within each subcategory.
ProductSalesRanking as
(
    select
        ProductKey,
        SubCategoryKey,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        dense_rank() over
        (
            partition by SubCategoryKey
            order by TotalQuantitySold desc
        ) as SalesVolumeRank
    from USProductSales
)

-- Return every product ranked first within its subcategory.
select
    pc.CategoryName,
    psc.SubCategoryName,
    psr.SalesVolumeRank,
    psr.ProductKey,
    p.ProductDescription,
    psr.DistinctCustomers,
    psr.TotalOrders,
    psr.TotalQuantitySold,
    cast(
        psr.TotalQuantitySold * 1.0
        / nullif(psr.TotalOrders, 0)
        as decimal(8, 2)
    ) as AverageUnitsPerOrder
from ProductSalesRanking as psr
inner join dbo.HMProducts as p
    on psr.ProductKey = p.ProductKey
inner join dbo.HMProductSubCategory as psc
    on psr.SubCategoryKey = psc.SubCategoryKey
inner join dbo.HMProductCategory as pc
    on psc.CategoryKey = pc.CategoryKey
where psr.SalesVolumeRank = 1
order by
    pc.CategoryName,
    psc.SubCategoryName,
    psr.ProductKey;

/*==============================================================
  Q7 Business Insight
  --------------------------------------------------------------
  The analysis identified 22 leading products across 20 product
  subcategories represented in United States sales.

  Two subcategories had tied sales-volume leaders, causing the
  number of returned products to exceed the number of represented
  subcategories.

  TC-127, an International heavy-duty tractor, recorded the
  highest sales volume among all subcategory leaders, with
  290 units sold across 191 orders.

  TC-127 also recorded the highest average units per order at
  1.52, indicating that its leading sales volume was supported
  by both repeat orders and multi-unit purchases.

  RD-521 led the Rock Drillers subcategory with 260 units sold
  across 216 orders and an average of 1.20 units per order.

  Most subcategory leaders averaged approximately one unit per
  order. Their sales volume was therefore driven primarily by
  repeated individual-unit orders rather than unusually large
  quantities within a small number of orders.

  CT-712 and CT-714 shared first place in the Compactors
  subcategory with 223 units sold each.

  IB-410 and IB-411 shared first place in the Ice Breakers
  subcategory with 229 units sold each. However, IB-411 reached
  111 distinct customers compared with 102 for IB-410.

  These ties demonstrate that equal sales volume does not
  necessarily indicate equal customer reach.

  RP-244 recorded the broadest customer reach among the
  subcategory leaders, with 114 distinct customers.

  One of the 21 product subcategories did not appear in the
  result because it had no qualifying sales among United States
  customers.

  Sales volume measures product movement but does not establish
  financial performance. Revenue, average revenue per unit, and
  profitability must also be considered before making inventory
  or product-prioritization decisions.
==============================================================*/

/*==============================================================
  Q7.1 Revenue Performance of Top-Selling Products
  --------------------------------------------------------------
  Business Question:
  Do the highest sales-volume products also rank highly in
  revenue within their respective product subcategories?

  Objective:
  Compare sales-volume and revenue rankings and evaluate total
  revenue and average revenue per unit among volume leaders.
==============================================================*/

-- Calculate sales volume, customer reach, order frequency,
-- and revenue for United States product sales.
;with USProductPerformance as
(
    select
        s.ProductKey,
        p.SubCategoryKey,
        count(distinct s.CustomerKey) as DistinctCustomers,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCustomers as c
        on s.CustomerKey = c.CustomerKey
    inner join dbo.HMProducts as p
        on s.ProductKey = p.ProductKey
    where c.Country = 'United States'
    group by
        s.ProductKey,
        p.SubCategoryKey
),

-- Rank products separately by sales volume and revenue
-- within each subcategory.
ProductPerformanceRanking as
(
    select
        ProductKey,
        SubCategoryKey,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by SubCategoryKey
            order by TotalQuantitySold desc
        ) as SalesVolumeRank,
        dense_rank() over
        (
            partition by SubCategoryKey
            order by TotalRevenue desc
        ) as RevenueRank
    from USProductPerformance
)

-- Return sales-volume leaders and their revenue performance.
select
    pc.CategoryName,
    psc.SubCategoryName,
    ppr.ProductKey,
    p.ProductDescription,
    ppr.SalesVolumeRank,
    ppr.RevenueRank,
    ppr.RevenueRank - ppr.SalesVolumeRank as RankGap,
    case
        when ppr.RevenueRank = 1
            then 'Also Revenue Leader'
        else 'Not Revenue Leader'
    end as RevenuePosition,
    ppr.DistinctCustomers,
    ppr.TotalOrders,
    ppr.TotalQuantitySold,
    cast(
        ppr.TotalQuantitySold * 1.0
        / nullif(ppr.TotalOrders, 0)
        as decimal(8, 2)
    ) as AverageUnitsPerOrder,
    cast(
        ppr.TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        ppr.TotalRevenue * 1.0
        / nullif(ppr.TotalQuantitySold, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerUnit
from ProductPerformanceRanking as ppr
inner join dbo.HMProducts as p
    on ppr.ProductKey = p.ProductKey
inner join dbo.HMProductSubCategory as psc
    on ppr.SubCategoryKey = psc.SubCategoryKey
inner join dbo.HMProductCategory as pc
    on psc.CategoryKey = pc.CategoryKey
where ppr.SalesVolumeRank = 1
order by
    pc.CategoryName,
    psc.SubCategoryName,
    ppr.ProductKey;

/*==============================================================
  Q7.1 Business Insight
  --------------------------------------------------------------
  Only four of the 22 sales-volume-leading products also ranked
  first in revenue within their respective subcategories.

  These four products were CR-110 in Cranes, RP-244 in Road
  Pavers, RD-521 in Rock Drillers, and IB-411 in Ice Breakers.

  Therefore, only four of the 20 represented subcategories, or
  20%, had a sales-volume leader that was also a revenue leader.

  RD-521 demonstrated particularly strong alignment between unit
  demand and financial performance. It sold 260 units, generated
  3.68 million in revenue, and ranked first in both sales volume
  and revenue within the Rock Drillers subcategory.

  TC-127 recorded the highest quantity sold among all displayed
  products, with 290 units, but ranked second in Tractor revenue.
  This confirms that the highest unit volume does not always
  produce the highest total revenue.

  The two Compactor volume leaders had very different financial
  positions despite selling 223 units each. CT-714 ranked third
  in revenue, while CT-712 ranked eighth.

  Among the tied Ice Breaker volume leaders, IB-411 ranked first
  in revenue and reached 111 customers, while IB-410 ranked third
  in revenue and reached 102 customers.

  EX-206 showed the largest difference between its volume and
  revenue positions. It ranked first in Excavator sales volume
  but only 11th in revenue, producing a rank gap of 10.

  FT-311, FL-121, and DT-800 also showed large rank gaps of
  eight positions between sales volume and revenue.

  Average revenue per unit varied substantially. FL-121 generated
  the lowest average among the displayed leaders at 2,444 per
  unit, while OR-899 generated the highest at 29,244 per unit.

  OR-899 generated 6.55 million, the highest total revenue among
  the displayed volume leaders, but ranked only fifth in Oil Rig
  revenue. This indicates that other products in that subcategory
  generated even greater revenue despite lower unit volume.

  Overall, sales volume, customer reach, total revenue, and
  revenue per unit provide different measures of product
  performance. A volume leader should not automatically be
  treated as the strongest financial performer.
==============================================================*/

/*==============================================================
  Q8. Detailed Profile of Top-Selling Products
  --------------------------------------------------------------
  Business Question:
  What are the brand, type, color, shipping time, and status
  characteristics of the highest sales-volume products within
  each subcategory among United States customers?

  Objective:
  Profile the sales-volume leaders identified in Q7 and examine
  whether common product characteristics appear among them.

  Analysis Scope:
  Only products ranked first in sales volume within their
  respective subcategories are included.
==============================================================*/

-- Calculate total sales volume for products purchased by
-- United States customers.
;with USProductSales as
(
    select
        s.ProductKey,
        p.SubCategoryKey,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold
    from dbo.HMSales as s
    inner join dbo.HMCustomers as c
        on s.CustomerKey = c.CustomerKey
    inner join dbo.HMProducts as p
        on s.ProductKey = p.ProductKey
    where c.Country = 'United States'
    group by
        s.ProductKey,
        p.SubCategoryKey
),

-- Rank products by quantity sold within each subcategory.
ProductSalesRanking as
(
    select
        ProductKey,
        SubCategoryKey,
        TotalQuantitySold,
        dense_rank() over
        (
            partition by SubCategoryKey
            order by TotalQuantitySold desc
        ) as SalesVolumeRank
    from USProductSales
)

-- Return product characteristics for all volume leaders.
select
    pc.CategoryName,
    psc.SubCategoryName,
    psr.SalesVolumeRank,
    psr.ProductKey,
    p.ProductDescription,
    p.Brand,
    p.Type,
    p.Color,
    p.ShipDays,
    p.Status,
    psr.TotalQuantitySold
from ProductSalesRanking as psr
inner join dbo.HMProducts as p
    on psr.ProductKey = p.ProductKey
inner join dbo.HMProductSubCategory as psc
    on psr.SubCategoryKey = psc.SubCategoryKey
inner join dbo.HMProductCategory as pc
    on psc.CategoryKey = pc.CategoryKey
where psr.SalesVolumeRank = 1
order by
    pc.CategoryName,
    psc.SubCategoryName,
    psr.ProductKey;

/*==============================================================
  Q8 Business Insight
  --------------------------------------------------------------
  All 22 sales-volume-leading products had an Active status in
  the product dimension.

  HeavyDuty was the most frequently represented product type,
  accounting for 12 of the 22 displayed products.

  LightDuty accounted for six products, while Standard accounted
  for four.

  However, this frequency does not prove that HeavyDuty products
  generally perform better. The distribution of product types
  across the complete product catalog must also be considered.

  No single brand strongly dominated the result. JCB was the only
  brand appearing more than once, represented by CT-712 in
  Compactors and BZ-801 in Bulldozers. All other brands appeared
  once.

  Shipping time ranged from five days for MT-473 to 20 days for
  OR-899.

  Six sales-volume leaders had shipping times of at least
  15 days: CT-714, FT-311, TC-127, BZ-801, OR-899, and LC-208.

  These longer shipping times may create fulfillment or inventory
  risks if demand for these products remains high.

  No clearly dominant color pattern appeared among the leaders.
  Product color should therefore not be treated as an explanation
  for sales-volume performance without comparison against the
  full product catalog.

  Product status, type, brand, color, and shipping time describe
  the leading products but do not establish the cause of their
  sales performance. Pricing, customer needs, product availability,
  profitability, and subcategory demand require further analysis.
==============================================================*/

/*==============================================================
  Product Analysis Summary
  --------------------------------------------------------------
  - The analysis identified 22 sales-volume-leading products
    across 20 product subcategories represented in United States
    sales.

  - Compactors and Ice Breakers each had two products tied for
    the highest sales volume in their subcategory.

  - TC-127 recorded the highest quantity sold among all displayed
    leaders, with 290 units.

  - Most sales-volume leaders averaged approximately one unit per
    order, indicating that repeated orders were the primary driver
    of volume.

  - Only four products ranked first in both sales volume and
    revenue: CR-110, RP-244, RD-521, and IB-411.

  - EX-206 showed the largest gap between sales-volume and revenue
    rankings, ranking first in volume but 11th in revenue.

  - Average revenue per unit ranged from 2,444 for FL-121 to
    29,244 for OR-899.

  - All displayed sales-volume leaders had an Active status.

  - HeavyDuty products represented 12 of the 22 leaders,
    LightDuty represented six, and Standard represented four.

  - JCB was the only brand appearing more than once among the
    sales-volume leaders.

  - Shipping time ranged from five to 20 days. Six leading
    products had shipping times of at least 15 days.

  - Sales volume, customer reach, revenue, and revenue per unit
    produced different views of product performance.
==============================================================*/


/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Prioritize availability monitoring for products that lead
     in both sales volume and revenue: CR-110, RP-244, RD-521,
     and IB-411.

  2. Review inventory levels, supplier lead times, and demand
     stability for high-volume products with shipping times of
     at least 15 days.

  3. Compare tied volume leaders using customer reach, revenue,
     revenue per unit, profitability, and product availability
     before selecting a preferred product.

  4. Investigate products with large volume-to-revenue rank gaps,
     including EX-206, FT-311, FL-121, and DT-800. Review unit
     pricing, discounts, customer segments, and product purpose.

  5. Do not classify lower-revenue-ranked volume leaders as weak
     products without evaluating their role in serving lower-price
     or high-frequency customer segments.

  6. Investigate why one product subcategory had no qualifying
     United States sales. Determine whether this reflects limited
     demand, distribution, availability, or incomplete data.

  7. Compare the frequency of product types, brands, colors, and
     shipping times among leaders with their frequency in the
     complete product catalog before concluding that an attribute
     is associated with stronger sales.

  8. Monitor the status of high-volume products to reduce the risk
     of an important product becoming unavailable or inactive.

  9. Combine sales volume and revenue analysis with product cost
     and profit margin before making inventory, marketing, or
     product-prioritization decisions.
==============================================================*/


/*==============================================================
  End of 04_05_Product_Analysis.sql
==============================================================*/

set nocount off;


