/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_07_Profitability_and_Geographic_Analysis.sql
  Section: Profitability and Geographic Customer Performance
==============================================================

Purpose:
Evaluate company profitability across complete sales years,
identify the products and subcategories contributing the most
profit, and analyze customer spending performance by country.

Analysis Scope:
- Q11: Most profitable complete year and top-contributing product
- Q11.1: Top 10 profit-contributing products in the most
  profitable year
- Q11.2: Profit contribution by product subcategory in the most
  profitable year
- Q12: Highest customer-spending year by country
- Q12.1: Customer value during each country's peak-spending year

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql
- 04_01_Dataset_Exploration.sql
- 04_02_Time_Analysis.sql
- 04_03_Customer_Analysis.sql
- 04_04_Store_Analysis.sql
- 04_05_Product_Analysis.sql
- 04_06_Channel_Analysis.sql

Important:
- Profit is calculated as:

      Quantity Sold * (Selling Price - Unit Cost)

- Profit margin is calculated as:

      Total Profit / Total Revenue * 100

- TransactionDate is used to assign sales to calendar years.
- Only years containing sales activity in all 12 months are
  included in annual profitability comparisons.
- The incomplete year 2013 is excluded from complete-year
  comparisons.
- Geographic analysis is based on the country assigned to each
  customer.
- Revenue and profit are presented in millions where appropriate.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q11. Most Profitable Year and Top-Contributing Product
  --------------------------------------------------------------
  Business Question:
  Which complete sales year generated the highest total profit,
  and which product contributed the most profit during that year?

  Objective:
  Identify the most profitable complete year and determine the
  product that generated the highest profit during that year.

  Profit Definition:
  Profit = Quantity Sold * (Selling Price - Unit Cost)
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Calculate revenue, cost, and profit for each complete year.
AnnualProfitPerformance as
(
    select
        c.Year,
        count(distinct s.Invoice) as AnnualTotalOrders,
        sum(cast(s.Qty as bigint)) as AnnualTotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as AnnualRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as AnnualCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as AnnualProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join CompleteSalesYears as cy
        on c.Year = cy.Year
    group by
        c.Year
),

-- Rank complete years by total profit.
AnnualProfitRanking as
(
    select
        Year,
        AnnualTotalOrders,
        AnnualTotalQuantitySold,
        AnnualRevenue,
        AnnualCost,
        AnnualProfit,
        AnnualProfit * 100.0
            / nullif(AnnualRevenue, 0)
            as AnnualProfitMarginPercent,
        dense_rank() over
        (
            order by AnnualProfit desc
        ) as ProfitYearRank
    from AnnualProfitPerformance
),

-- Calculate product profitability in the most profitable year.
ProductProfitInTopYear as
(
    select
        apr.Year,
        s.ProductKey,
        count(distinct s.Invoice) as ProductTotalOrders,
        sum(cast(s.Qty as bigint)) as ProductTotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as ProductRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as ProductCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as ProductProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join AnnualProfitRanking as apr
        on c.Year = apr.Year
        and apr.ProfitYearRank = 1
    group by
        apr.Year,
        s.ProductKey
),

-- Rank products by profit and calculate their contribution
-- to total profit in the selected year.
ProductProfitRanking as
(
    select
        Year,
        ProductKey,
        ProductTotalOrders,
        ProductTotalQuantitySold,
        ProductRevenue,
        ProductCost,
        ProductProfit,
        ProductProfit * 100.0
            / nullif(
                sum(ProductProfit) over
                (
                    partition by Year
                ),
                0
            ) as ProfitContributionPercent,
        ProductProfit * 100.0
            / nullif(ProductRevenue, 0)
            as ProductProfitMarginPercent,
        dense_rank() over
        (
            partition by Year
            order by ProductProfit desc
        ) as ProductProfitRank
    from ProductProfitInTopYear
)

-- Return the most profitable complete year and its
-- highest-profit product.
select
    apr.ProfitYearRank,
    apr.Year,
    apr.AnnualTotalOrders,
    apr.AnnualTotalQuantitySold,
    cast(
        apr.AnnualRevenue / 1000000.0
        as decimal(12, 2)
    ) as AnnualRevenue_Million,
    cast(
        apr.AnnualCost / 1000000.0
        as decimal(12, 2)
    ) as AnnualCost_Million,
    cast(
        apr.AnnualProfit / 1000000.0
        as decimal(12, 2)
    ) as AnnualProfit_Million,
    cast(
        apr.AnnualProfitMarginPercent
        as decimal(6, 2)
    ) as AnnualProfitMarginPercent,
    ppr.ProductProfitRank,
    ppr.ProductKey,
    p.ProductDescription,
    ppr.ProductTotalOrders,
    ppr.ProductTotalQuantitySold,
    cast(
        ppr.ProductRevenue / 1000000.0
        as decimal(12, 2)
    ) as ProductRevenue_Million,
    cast(
        ppr.ProductCost / 1000000.0
        as decimal(12, 2)
    ) as ProductCost_Million,
    cast(
        ppr.ProductProfit / 1000000.0
        as decimal(12, 2)
    ) as ProductProfit_Million,
    cast(
        ppr.ProfitContributionPercent
        as decimal(6, 2)
    ) as ProfitContributionPercent,
    cast(
        ppr.ProductProfitMarginPercent
        as decimal(6, 2)
    ) as ProductProfitMarginPercent
from AnnualProfitRanking as apr
inner join ProductProfitRanking as ppr
    on apr.Year = ppr.Year
    and ppr.ProductProfitRank = 1
inner join dbo.HMProducts as p
    on ppr.ProductKey = p.ProductKey
where apr.ProfitYearRank = 1
order by
    apr.Year,
    ppr.ProductKey;

/*==============================================================
  Q11 Business Insight
  --------------------------------------------------------------
  The most profitable complete sales year was 2008.

  During that year, the company generated 592.48 million in
  revenue from 73,486 distinct orders and 74,072 units sold.

  Total cost was 490.96 million, resulting in 101.51 million in
  total profit and an annual profit margin of 17.13%.

  OR-895, described as OilRigs-AtlasCopco-Standard-Red, was the
  highest-profit product in 2008.

  The product generated 13.55 million in revenue and 3.73 million
  in profit from 303 orders and 303 units sold.

  OR-895 achieved a profit margin of 27.54%, which was 10.41
  percentage points higher than the overall annual profit margin.

  Despite ranking first in product profit, OR-895 contributed
  only 3.68% of the company's total profit in 2008.

  This relatively small contribution indicates that annual profit
  was distributed across a broad product portfolio rather than
  being dominated by a single product.

  The product's order count and quantity sold were both 303,
  indicating an average of one unit per order during the year.
==============================================================*/

/*==============================================================
  Q11.1 Top 10 Profit-Contributing Products in the Most
        Profitable Year
  --------------------------------------------------------------
  Business Question:
  Which products generated the highest profits during the most
  profitable complete year, and how much of annual profit did
  the top 10 profit ranks collectively contribute?

  Objective:
  Rank products by total profit and evaluate whether annual
  profit was concentrated among a small group of products.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Calculate total profit for each complete year.
AnnualProfitPerformance as
(
    select
        c.Year,
        sum(cast(s.Revenue as bigint)) as AnnualRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as AnnualCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as AnnualProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join CompleteSalesYears as cy
        on c.Year = cy.Year
    group by
        c.Year
),

-- Rank complete years by total profit.
AnnualProfitRanking as
(
    select
        Year,
        AnnualRevenue,
        AnnualCost,
        AnnualProfit,
        dense_rank() over
        (
            order by AnnualProfit desc
        ) as ProfitYearRank
    from AnnualProfitPerformance
),

-- Calculate product profitability in the most profitable year.
ProductProfitInTopYear as
(
    select
        apr.Year,
        s.ProductKey,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as ProductRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as ProductCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as ProductProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join AnnualProfitRanking as apr
        on c.Year = apr.Year
        and apr.ProfitYearRank = 1
    group by
        apr.Year,
        s.ProductKey
),

-- Rank products and calculate individual profit contribution.
ProductProfitRanking as
(
    select
        Year,
        ProductKey,
        TotalOrders,
        TotalQuantitySold,
        ProductRevenue,
        ProductCost,
        ProductProfit,
        dense_rank() over
        (
            partition by Year
            order by ProductProfit desc
        ) as ProductProfitRank,
        ProductProfit * 100.0
            / nullif(
                sum(ProductProfit) over
                (
                    partition by Year
                ),
                0
            ) as IndividualProfitContributionPercent,
        ProductProfit * 100.0
            / nullif(ProductRevenue, 0)
            as ProductProfitMarginPercent
    from ProductProfitInTopYear
),

-- Retain the top 10 profit ranks and calculate their combined
-- profit and annual contribution.
Top10ProfitProducts as
(
    select
        Year,
        ProductProfitRank,
        ProductKey,
        TotalOrders,
        TotalQuantitySold,
        ProductRevenue,
        ProductCost,
        ProductProfit,
        IndividualProfitContributionPercent,
        ProductProfitMarginPercent,
        sum(ProductProfit) over
        (
            partition by Year
        ) as Top10CombinedProfit,
        sum(IndividualProfitContributionPercent) over
        (
            partition by Year
        ) as Top10CombinedProfitContributionPercent
    from ProductProfitRanking
    where ProductProfitRank <= 10
)

-- Return the top profit-generating products and their combined
-- contribution to annual profit.
select
    t10.Year,
    t10.ProductProfitRank,
    t10.ProductKey,
    p.ProductDescription,
    pc.CategoryName,
    psc.SubCategoryName,
    t10.TotalOrders,
    t10.TotalQuantitySold,
    cast(
        t10.ProductRevenue / 1000000.0
        as decimal(12, 2)
    ) as ProductRevenue_Million,
    cast(
        t10.ProductCost / 1000000.0
        as decimal(12, 2)
    ) as ProductCost_Million,
    cast(
        t10.ProductProfit / 1000000.0
        as decimal(12, 2)
    ) as ProductProfit_Million,
    cast(
        t10.ProductProfitMarginPercent
        as decimal(6, 2)
    ) as ProductProfitMarginPercent,
    cast(
        t10.IndividualProfitContributionPercent
        as decimal(6, 2)
    ) as IndividualProfitContributionPercent,
    cast(
        apr.AnnualProfit / 1000000.0
        as decimal(12, 2)
    ) as AnnualProfit_Million,
    cast(
        t10.Top10CombinedProfit / 1000000.0
        as decimal(12, 2)
    ) as Top10CombinedProfit_Million,
    cast(
        t10.Top10CombinedProfitContributionPercent
        as decimal(6, 2)
    ) as Top10CombinedProfitContributionPercent
from Top10ProfitProducts as t10
inner join AnnualProfitRanking as apr
    on t10.Year = apr.Year
    and apr.ProfitYearRank = 1
inner join dbo.HMProducts as p
    on t10.ProductKey = p.ProductKey
inner join dbo.HMProductSubCategory as psc
    on p.SubCategoryKey = psc.SubCategoryKey
inner join dbo.HMProductCategory as pc
    on psc.CategoryKey = pc.CategoryKey
order by
    t10.ProductProfitRank,
    t10.ProductKey;

/*==============================================================
  Q11.1 Business Insight
  --------------------------------------------------------------
  The top 10 profit-ranked products generated a combined profit
  of 18.07 million in 2008.

  This represented only 17.80% of the total annual profit of
  101.51 million. Therefore, the remaining products generated
  82.20%, or approximately 83.44 million, of annual profit.

  OR-895 ranked first with 3.73 million in profit and contributed
  3.68% of total annual profit.

  OR-889 and OR-896 ranked second and third, generating 2.69
  million and 2.40 million in profit respectively.

  Seven of the top 10 products belonged to the OilRigs
  subcategory, while the remaining three belonged to
  RockDrillers.

  All five of the highest-profit products were OilRigs. This
  indicates a visible concentration pattern among the leading
  individual products.

  Product profit margins varied considerably, ranging from
  11.50% for OR-898 to 27.54% for OR-895.

  RD-519 achieved a 27.53% profit margin, almost equal to OR-895,
  despite generating a much lower total profit of 1.24 million.

  OR-898 generated 10.60 million in revenue, one of the highest
  revenue amounts among the displayed products, but ranked only
  eighth in profit because its margin was only 11.50%.

  This demonstrates that high product revenue does not
  necessarily produce high profit when product costs are also
  high.

  RD-512 was the only displayed product with a noticeably higher
  quantity sold than order count, selling 344 units across
  306 orders. For most other top products, orders and quantities
  were equal.

  Although the top 10 products were concentrated in only two
  subcategories, they generated less than one-fifth of annual
  profit. Profit was therefore broadly distributed at the
  individual-product level.

  Subcategory-level profitability must be examined separately
  to determine whether OilRigs and RockDrillers represented a
  more significant concentration of annual profit.
==============================================================*/

/*==============================================================
  Q11.2 Profit Contribution by Product Subcategory in the Most
        Profitable Year
  --------------------------------------------------------------
  Business Question:
  Which product subcategories generated the highest profits
  during the most profitable complete year, and how much did
  each subcategory contribute to annual profit?

  Objective:
  Evaluate profit concentration at the product-subcategory level
  and determine whether the strong presence of OilRigs and
  RockDrillers among the top products reflects broader
  subcategory performance.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Calculate total financial performance for each complete year.
AnnualProfitPerformance as
(
    select
        c.Year,
        sum(cast(s.Revenue as bigint)) as AnnualRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as AnnualCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as AnnualProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join CompleteSalesYears as cy
        on c.Year = cy.Year
    group by
        c.Year
),

-- Rank complete years by total profit.
AnnualProfitRanking as
(
    select
        Year,
        AnnualRevenue,
        AnnualCost,
        AnnualProfit,
        dense_rank() over
        (
            order by AnnualProfit desc
        ) as ProfitYearRank
    from AnnualProfitPerformance
),

-- Calculate financial performance for each product subcategory
-- during the most profitable year.
SubCategoryProfitInTopYear as
(
    select
        apr.Year,
        pc.CategoryKey,
        pc.CategoryName,
        psc.SubCategoryKey,
        psc.SubCategoryName,
        count(distinct s.ProductKey) as DistinctProducts,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as SubCategoryRevenue,
        sum(
            cast(s.Qty as bigint)
            * cast(s.Cost as bigint)
        ) as SubCategoryCost,
        sum(
            cast(s.Qty as bigint)
            * (
                cast(s.Price as bigint)
                - cast(s.Cost as bigint)
            )
        ) as SubCategoryProfit
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join AnnualProfitRanking as apr
        on c.Year = apr.Year
        and apr.ProfitYearRank = 1
    inner join dbo.HMProducts as p
        on s.ProductKey = p.ProductKey
    inner join dbo.HMProductSubCategory as psc
        on p.SubCategoryKey = psc.SubCategoryKey
    inner join dbo.HMProductCategory as pc
        on psc.CategoryKey = pc.CategoryKey
    group by
        apr.Year,
        pc.CategoryKey,
        pc.CategoryName,
        psc.SubCategoryKey,
        psc.SubCategoryName
),

-- Rank subcategories and calculate profit contribution,
-- cumulative contribution, and profit margin.
SubCategoryProfitMetrics as
(
    select
        Year,
        CategoryKey,
        CategoryName,
        SubCategoryKey,
        SubCategoryName,
        DistinctProducts,
        TotalOrders,
        TotalQuantitySold,
        SubCategoryRevenue,
        SubCategoryCost,
        SubCategoryProfit,
        dense_rank() over
        (
            partition by Year
            order by SubCategoryProfit desc
        ) as SubCategoryProfitRank,
        SubCategoryProfit * 100.0
            / nullif(
                sum(SubCategoryProfit) over
                (
                    partition by Year
                ),
                0
            ) as ProfitContributionPercent,
        sum(SubCategoryProfit) over
        (
            partition by Year
            order by
                SubCategoryProfit desc,
                SubCategoryKey
            rows between unbounded preceding and current row
        ) * 100.0
            / nullif(
                sum(SubCategoryProfit) over
                (
                    partition by Year
                ),
                0
            ) as CumulativeProfitContributionPercent,
        SubCategoryProfit * 100.0
            / nullif(SubCategoryRevenue, 0)
            as ProfitMarginPercent
    from SubCategoryProfitInTopYear
)

-- Return all product subcategories ranked by total profit.
select
    Year,
    SubCategoryProfitRank,
    CategoryName,
    SubCategoryName,
    DistinctProducts,
    TotalOrders,
    TotalQuantitySold,
    cast(
        SubCategoryRevenue / 1000000.0
        as decimal(12, 2)
    ) as SubCategoryRevenue_Million,
    cast(
        SubCategoryCost / 1000000.0
        as decimal(12, 2)
    ) as SubCategoryCost_Million,
    cast(
        SubCategoryProfit / 1000000.0
        as decimal(12, 2)
    ) as SubCategoryProfit_Million,
    cast(
        ProfitContributionPercent
        as decimal(6, 2)
    ) as ProfitContributionPercent,
    cast(
        CumulativeProfitContributionPercent
        as decimal(6, 2)
    ) as CumulativeProfitContributionPercent,
    cast(
        ProfitMarginPercent
        as decimal(6, 2)
    ) as ProfitMarginPercent
from SubCategoryProfitMetrics
order by
    SubCategoryProfitRank,
    SubCategoryKey;

/*==============================================================
  Q11.2 Business Insight
  --------------------------------------------------------------
  OilRigs was the highest-profit product subcategory in 2008.

  It generated 109.66 million in revenue and 16.97 million in
  profit, contributing 16.72% of total annual profit.

  RockDrillers ranked second with 8.32 million in profit and an
  8.19% contribution.

  Together, OilRigs and RockDrillers generated 24.91% of total
  annual profit.

  RoadPavers ranked third with 7.65 million in profit and a
  7.53% contribution. The three leading subcategories therefore
  generated 32.44% of annual profit.

  The top 10 subcategories collectively contributed 69.55% of
  annual profit. This shows that profit was considerably more
  concentrated at the subcategory level than at the individual
  product level, where the top 10 products contributed only
  17.80%.

  OilRigs achieved a profit margin of 15.48%, below the overall
  annual profit margin of 17.13%.

  Its first-place profit position was therefore driven primarily
  by its exceptionally high revenue volume rather than superior
  profit-margin efficiency.

  RoadPavers achieved the highest profit margin among all
  subcategories at 22.41%, despite ranking third in total profit.

  Harvesters and TunnelBores also produced strong margins of
  20.87% and 20.84%, respectively, but their lower revenue
  volumes limited their total profit contributions.

  IceBreakers ranked last with 1.90 million in profit and a
  1.87% contribution. Its profit margin was 14.83%.

  Every subcategory contained 12 distinct products. Therefore,
  differences in subcategory profit were not caused by unequal
  numbers of represented products.

  Order volume was also relatively similar across subcategories.
  The substantial financial differences were more closely
  associated with product pricing, cost structure, and product
  mix than with the number of products or orders alone.

  Overall, total profit and profit margin produced different
  views of subcategory performance. High-profit subcategories
  were not always the most margin-efficient.
==============================================================*/

/*==============================================================
  Q12. Highest Customer-Spending Year by Country
  --------------------------------------------------------------
  Business Question:
  In which complete year did customers from each country
  generate their highest total spending?

  Objective:
  Identify the highest-spending complete year for every customer
  country and compare peak market performance across countries.

  Spending Definition:
  Customer spending is represented by total sales revenue.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Calculate annual customer spending for every country.
CountryAnnualSpending as
(
    select
        cu.Country,
        cu.Continent,
        c.Year,
        count(distinct s.CustomerKey) as DistinctCustomers,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalSpending
    from dbo.HMSales as s
    inner join dbo.HMCustomers as cu
        on s.CustomerKey = cu.CustomerKey
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join CompleteSalesYears as cy
        on c.Year = cy.Year
    group by
        cu.Country,
        cu.Continent,
        c.Year
),

-- Rank complete years separately for each country.
CountrySpendingRanking as
(
    select
        Country,
        Continent,
        Year,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending,
        dense_rank() over
        (
            partition by Country
            order by TotalSpending desc
        ) as SpendingYearRank
    from CountryAnnualSpending
),

-- Retain every country's highest-spending year.
PeakCountryYears as
(
    select
        Country,
        Continent,
        Year,
        SpendingYearRank,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending
    from CountrySpendingRanking
    where SpendingYearRank = 1
),

-- Compare peak-spending results across countries and years.
PeakCountryMetrics as
(
    select
        Country,
        Continent,
        Year,
        SpendingYearRank,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending,
        dense_rank() over
        (
            order by TotalSpending desc
        ) as CountryPeakSpendingRank,
        count(*) over
        (
            partition by Year
        ) as CountriesPeakingInSameYear
    from PeakCountryYears
)

-- Return the highest-spending complete year for each country.
select
    CountryPeakSpendingRank,
    Country,
    Continent,
    Year as PeakSpendingYear,
    CountriesPeakingInSameYear,
    DistinctCustomers,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalSpending / 1000000.0
        as decimal(12, 2)
    ) as PeakSpending_Million
from PeakCountryMetrics
order by
    Continent,
    Country,
    PeakSpendingYear;

/*==============================================================
  Q12 Business Insight
  --------------------------------------------------------------
  Peak customer-spending years varied substantially across the
  39 countries included in the analysis.

  The United States recorded the highest country-level peak,
  generating 49.10 million in 2002 from 126 customers and
  6,055 distinct orders.

  Australia ranked second with 25.03 million in 2009, followed
  by India with 24.34 million in 2002 and Switzerland with
  24.11 million in 2004.

  Congo ranked fifth with 22.43 million in 2012, making it the
  highest-ranked African market based on peak-year spending.

  The year 2002 was the most frequently observed peak-spending
  year, representing the highest-spending year for 12 of the
  39 countries.

  Eight countries reached their peak in 2012, while six reached
  their peak in 2011. Therefore, 14 countries, approximately
  35.90% of the markets, recorded their highest spending during
  the two most recent complete years.

  The distribution of peak years shows that customer markets did
  not develop uniformly. Some countries reached their strongest
  performance early in the analysis period, while others reached
  their peak much later.

  Spain recorded the lowest peak-year spending at 1.81 million
  in 2002, followed by Uganda with 2.22 million in 2003.

  However, low total spending does not necessarily indicate low
  customer value. Spain's peak result was generated by only
  three distinct customers, while larger markets generally
  included many more customers.

  Switzerland had the largest number of distinct customers in
  its peak year, with 133 customers, while the United States
  recorded the highest order volume.

  Overall, country-level peak spending was influenced by a
  combination of customer population, order frequency, quantity
  sold, and value generated per transaction.

  Average revenue per customer and per order must be evaluated
  to distinguish large customer markets from smaller markets
  containing potentially high-value customers.
==============================================================*/

/*==============================================================
  Q12.1 Customer Value During Each Country's Peak-Spending Year
  --------------------------------------------------------------
  Business Question:
  During each country's highest-spending year, how much revenue
  was generated per customer and per order?

  Objective:
  Compare total market spending with average customer value,
  average order value, order frequency, and units per order to
  distinguish large markets from high-value customer markets.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Calculate annual customer spending for each country.
CountryAnnualSpending as
(
    select
        cu.Country,
        cu.Continent,
        c.Year,
        count(distinct s.CustomerKey) as DistinctCustomers,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalSpending
    from dbo.HMSales as s
    inner join dbo.HMCustomers as cu
        on s.CustomerKey = cu.CustomerKey
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join CompleteSalesYears as cy
        on c.Year = cy.Year
    group by
        cu.Country,
        cu.Continent,
        c.Year
),

-- Rank complete years separately for each country.
CountrySpendingRanking as
(
    select
        Country,
        Continent,
        Year,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending,
        dense_rank() over
        (
            partition by Country
            order by TotalSpending desc
        ) as SpendingYearRank
    from CountryAnnualSpending
),

-- Calculate customer and order value during each country's
-- highest-spending year.
PeakYearCustomerValue as
(
    select
        Country,
        Continent,
        Year,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending,
        TotalSpending * 1.0
            / nullif(DistinctCustomers, 0)
            as AverageSpendingPerCustomer,
        TotalSpending * 1.0
            / nullif(TotalOrders, 0)
            as AverageOrderValue,
        TotalOrders * 1.0
            / nullif(DistinctCustomers, 0)
            as AverageOrdersPerCustomer,
        TotalQuantitySold * 1.0
            / nullif(TotalOrders, 0)
            as AverageUnitsPerOrder
    from CountrySpendingRanking
    where SpendingYearRank = 1
),

-- Rank countries by market size, average customer value,
-- and average order value.
CountryCustomerValueRanking as
(
    select
        Country,
        Continent,
        Year,
        DistinctCustomers,
        TotalOrders,
        TotalQuantitySold,
        TotalSpending,
        AverageSpendingPerCustomer,
        AverageOrderValue,
        AverageOrdersPerCustomer,
        AverageUnitsPerOrder,
        dense_rank() over
        (
            order by TotalSpending desc
        ) as TotalSpendingRank,
        dense_rank() over
        (
            order by AverageSpendingPerCustomer desc
        ) as CustomerValueRank,
        dense_rank() over
        (
            order by AverageOrderValue desc
        ) as OrderValueRank
    from PeakYearCustomerValue
)

-- Return customer-value metrics for every country during
-- its highest-spending complete year.
select
    CustomerValueRank,
    TotalSpendingRank,
    OrderValueRank,
    Country,
    Continent,
    Year as PeakSpendingYear,
    DistinctCustomers,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalSpending / 1000000.0
        as decimal(12, 2)
    ) as TotalSpending_Million,
    cast(
        AverageSpendingPerCustomer
        as decimal(14, 2)
    ) as AverageSpendingPerCustomer,
    cast(
        AverageOrderValue
        as decimal(12, 2)
    ) as AverageOrderValue,
    cast(
        AverageOrdersPerCustomer
        as decimal(10, 2)
    ) as AverageOrdersPerCustomer,
    cast(
        AverageUnitsPerOrder
        as decimal(8, 2)
    ) as AverageUnitsPerOrder
from CountryCustomerValueRanking
order by
    CustomerValueRank,
    Country;

/*==============================================================
  Q12.1 Business Insight
  --------------------------------------------------------------
  Country rankings changed substantially when performance was
  measured by average spending per customer instead of total
  market spending.

  Spain ranked first in average spending per customer at
  602,737.33, despite ranking last in total peak-year spending.

  However, Spain's result was based on only three customers.
  Each customer placed an average of 73 orders, indicating that
  the high average was heavily influenced by a very small and
  highly active customer base.

  Japan ranked second in customer value at 402,292.83 per
  customer, followed by Norway at 393,716.00.

  The United States demonstrated the strongest combination of
  market scale and customer value. It ranked first in total
  spending and fourth in average spending per customer at
  389,711.64 across 126 customers.

  India also combined strong scale and customer value, ranking
  third in total spending and fifth in average customer value.

  Australia ranked second in total spending but only 16th in
  average customer value. Switzerland ranked fourth in total
  spending but 32nd in customer value.

  Congo and Russia also achieved high total-spending ranks but
  relatively low average customer-value ranks. Russia ranked
  seventh in total spending but last in average spending per
  customer.

  These results indicate that their strong market totals were
  driven primarily by larger customer populations rather than
  unusually high spending by each customer.

  New Zealand recorded the highest average order value at
  9,447.38, followed by Brazil at 8,934.29.

  Brazil also recorded the highest average units per order at
  1.12. Most other countries averaged approximately one unit
  per order.

  Average order values were considerably more consistent than
  average customer values. This indicates that differences in
  customer value were influenced strongly by order frequency.

  Markets with small customer populations and high averages
  should not automatically be treated as large or stable
  markets. A small number of customers can substantially affect
  the average.

  Overall, total spending, customer count, order frequency,
  average customer value, and average order value provide
  different perspectives on geographic performance and should
  be evaluated together.
==============================================================*/

/*==============================================================
  Profitability and Geographic Analysis Summary
  --------------------------------------------------------------
  - The most profitable complete sales year was 2008, generating
    101.51 million in profit with a 17.13% profit margin.

  - OR-895 was the highest-profit product in 2008, generating
    3.73 million in profit with a 27.54% margin.

  - OR-895 contributed only 3.68% of annual profit, showing that
    profit was not dominated by one individual product.

  - The top 10 products collectively generated 18.07 million,
    representing 17.80% of annual profit.

  - Seven of the top 10 profit-generating products were OilRigs,
    while three were RockDrillers.

  - OilRigs was the highest-profit subcategory, generating
    16.97 million and contributing 16.72% of annual profit.

  - OilRigs and RockDrillers collectively contributed 24.91% of
    annual profit.

  - The top 10 subcategories contributed 69.55% of annual profit,
    showing greater concentration at the subcategory level than
    at the individual-product level.

  - RoadPavers achieved the highest subcategory profit margin at
    22.41%, despite ranking third in total subcategory profit.

  - Peak customer-spending years varied across the 39 countries
    included in the geographic analysis.

  - The United States recorded the highest country-level peak,
    generating 49.10 million in 2002.

  - The United States also combined market scale with strong
    customer value, ranking fourth in average spending per
    customer.

  - Spain ranked first in average spending per customer but last
    in total spending because its result was based on only three
    highly active customers.

  - New Zealand recorded the highest average order value, while
    Brazil recorded the highest average units per order.

  - Geographic performance differed substantially depending on
    whether it was measured by total spending, customer value,
    order value, or customer population.
==============================================================*/


/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Investigate the pricing, cost structure, customer demand,
     and product positioning of OR-895 to understand the factors
     supporting its above-average profit margin.

  2. Maintain a diversified product portfolio because no single
     product made a dominant contribution to annual profit.

  3. Protect the strong revenue position of OilRigs while
     investigating opportunities to improve its 15.48% profit
     margin through pricing or cost optimization.

  4. Evaluate responsible growth opportunities for high-margin
     subcategories such as RoadPavers, Harvesters, and
     TunnelBores.

  5. Use both total profit and profit margin when evaluating
     products and subcategories. High revenue or profit volume
     does not necessarily indicate strong financial efficiency.

  6. Develop country-specific strategies because customer
     markets reached their peak performance in different years.

  7. Examine countries with early peak years for changes in
     customer activity, competition, product demand, and market
     coverage.

  8. Review countries with recent peak years for sustainable
     growth opportunities rather than assuming that recent
     performance will continue automatically.

  9. Prioritize markets that combine scale with strong customer
     value, such as the United States and India, while still
     considering profitability and market costs.

  10. Evaluate small high-value markets at the individual
      customer level because a small number of customers can
      strongly influence average-spending metrics.

  11. Monitor customer concentration risk in markets such as
      Spain, where peak-year performance depended on very few
      customers.

  12. Combine total spending, customer population, order
      frequency, average order value, and profitability before
      making geographic investment decisions.
==============================================================*/


/*==============================================================
  End of 04_07_Profitability_and_Geographic_Analysis.sql
==============================================================*/

set nocount off;
