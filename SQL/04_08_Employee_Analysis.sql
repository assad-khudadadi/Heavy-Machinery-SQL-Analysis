/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_08_Employee_Analysis.sql
  Section: Employee Sales Performance
==============================================================

Purpose:
Evaluate employee sales activity during 2011 by comparing order
volume, revenue generation, customer reach, average order value,
and differences between order-based and revenue-based rankings.

Analysis Scope:
- Q13: Top 5 employees by number of orders in 2011
- Q14: Top 5 employees by total revenue in 2011
- Q14.1: Comparison of employee order-volume and revenue
  performance in 2011

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
- 04_07_Profitability_and_Geographic_Analysis.sql

Important:
- One distinct Invoice represents one customer order.
- Employee revenue is measured using total sales revenue.
- Employee performance is analyzed only for the 2011 calendar
  year.
- Employee information is limited to EmpKey because the dataset
  does not include a separate employee dimension table.
- Order volume and total revenue represent different measures
  of performance and must be evaluated separately.
- Revenue is presented in millions where appropriate.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q13. Top 5 Employees by Number of Orders in 2011
  --------------------------------------------------------------
  Business Question:
  Which employees processed the highest number of distinct
  customer orders during 2011?

  Objective:
  Identify employees in the top five order-volume ranks and
  evaluate their individual and combined contribution to total
  annual order activity.

  Order Definition:
  One distinct Invoice represents one customer order.
==============================================================*/

-- Calculate order activity and supporting performance measures
-- for every employee during 2011.
;with EmployeeOrderPerformance2011 as
(
    select
        c.Year,
        s.EmpKey,
        count(distinct s.Invoice) as TotalOrders,
        count(distinct s.CustomerKey) as DistinctCustomers,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    where c.Year = 2011
    group by
        c.Year,
        s.EmpKey
),

-- Rank employees by total orders and calculate their individual
-- contribution to annual order activity.
EmployeeOrderRanking as
(
    select
        Year,
        EmpKey,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalOrders desc
        ) as EmployeeOrderRank,
        TotalOrders * 100.0
            / nullif(
                sum(TotalOrders) over
                (
                    partition by Year
                ),
                0
            ) as OrderContributionPercent,
        count(*) over
        (
            partition by Year
        ) as TotalEmployees
    from EmployeeOrderPerformance2011
),

-- Retain employees included in the top five rank positions and
-- calculate their combined order contribution.
Top5OrderRankEmployees as
(
    select
        Year,
        EmployeeOrderRank,
        EmpKey,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        OrderContributionPercent,
        TotalEmployees,
        count(*) over
        (
            partition by Year
        ) as EmployeesIncludedInTop5Ranks,
        sum(TotalOrders) over
        (
            partition by Year
        ) as Top5RanksCombinedOrders,
        sum(OrderContributionPercent) over
        (
            partition by Year
        ) as Top5RanksCombinedOrderContributionPercent
    from EmployeeOrderRanking
    where EmployeeOrderRank <= 5
)

-- Return employees included in the top five order-volume ranks.
select
    Year,
    EmployeeOrderRank,
    EmpKey,
    TotalEmployees,
    EmployeesIncludedInTop5Ranks,
    TotalOrders,
    cast(
        OrderContributionPercent
        as decimal(6, 2)
    ) as OrderContributionPercent,
    Top5RanksCombinedOrders,
    cast(
        Top5RanksCombinedOrderContributionPercent
        as decimal(6, 2)
    ) as Top5RanksCombinedOrderContributionPercent,
    DistinctCustomers,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        TotalRevenue * 1.0
        / nullif(TotalOrders, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerOrder
from Top5OrderRankEmployees
order by
    EmployeeOrderRank,
    EmpKey;

/*==============================================================
  Q13 Business Insight
  --------------------------------------------------------------
  The dataset contained 15 employees with sales activity during
  2011.

  E06 ranked first in order volume, processing 4,959 distinct
  orders and contributing 6.76% of total annual order activity.

  Because several employees had identical order counts, the top
  five rank positions included seven employees.

  These seven employees collectively processed 34,494 orders,
  representing 47.05% of all orders recorded in 2011.

  Individual order contribution among the leading employees
  ranged only from 6.68% for E03 to 6.76% for E06.

  The difference between the highest and lowest order totals
  among these employees was only 63 orders.

  This narrow range indicates that operational order activity
  was distributed relatively evenly and that no individual
  employee dominated the annual workload.

  E04 and E12 both processed 4,941 orders and shared second
  place. However, E12 generated 40.99 million in revenue,
  compared with 39.51 million for E04.

  E12 also recorded the highest average revenue per order among
  the displayed employees at 8,294.99.

  E08 and E15 both processed 4,924 orders and shared third place,
  but their revenue totals and average order values were also
  different.

  E02 reached the largest number of distinct customers among the
  displayed employees, serving 2,129 customers despite ranking
  fourth in order volume.

  These differences demonstrate that equal or similar order
  volume does not necessarily indicate equal revenue performance,
  customer reach, or average order value.

  Employee performance must therefore be evaluated using revenue
  and customer metrics in addition to operational order volume.
==============================================================*/

/*==============================================================
  Q14. Top 5 Employees by Total Revenue in 2011
  --------------------------------------------------------------
  Business Question:
  Which employees generated the highest total sales revenue
  during 2011?

  Objective:
  Identify employees in the top five revenue ranks and evaluate
  their individual and combined contribution to annual revenue.
==============================================================*/

-- Calculate revenue performance and supporting measures for
-- every employee during 2011.
;with EmployeeRevenuePerformance2011 as
(
    select
        c.Year,
        s.EmpKey,
        count(distinct s.Invoice) as TotalOrders,
        count(distinct s.CustomerKey) as DistinctCustomers,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    where c.Year = 2011
    group by
        c.Year,
        s.EmpKey
),

-- Rank employees by revenue and calculate their individual
-- contribution to annual revenue.
EmployeeRevenueRanking as
(
    select
        Year,
        EmpKey,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as EmployeeRevenueRank,
        TotalRevenue * 100.0
            / nullif(
                sum(TotalRevenue) over
                (
                    partition by Year
                ),
                0
            ) as RevenueContributionPercent,
        TotalRevenue * 1.0
            / nullif(TotalOrders, 0)
            as AverageRevenuePerOrder,
        count(*) over
        (
            partition by Year
        ) as TotalEmployees
    from EmployeeRevenuePerformance2011
),

-- Retain employees included in the top five revenue ranks and
-- calculate their combined revenue contribution.
Top5RevenueRankEmployees as
(
    select
        Year,
        EmployeeRevenueRank,
        EmpKey,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        RevenueContributionPercent,
        AverageRevenuePerOrder,
        TotalEmployees,
        count(*) over
        (
            partition by Year
        ) as EmployeesIncludedInTop5Ranks,
        sum(TotalRevenue) over
        (
            partition by Year
        ) as Top5RanksCombinedRevenue,
        sum(RevenueContributionPercent) over
        (
            partition by Year
        ) as Top5RanksCombinedRevenueContributionPercent
    from EmployeeRevenueRanking
    where EmployeeRevenueRank <= 5
)

-- Return employees included in the top five revenue ranks.
select
    Year,
    EmployeeRevenueRank,
    EmpKey,
    TotalEmployees,
    EmployeesIncludedInTop5Ranks,
    TotalOrders,
    DistinctCustomers,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        RevenueContributionPercent
        as decimal(6, 2)
    ) as RevenueContributionPercent,
    cast(
        AverageRevenuePerOrder
        as decimal(12, 2)
    ) as AverageRevenuePerOrder,
    cast(
        Top5RanksCombinedRevenue / 1000000.0
        as decimal(12, 2)
    ) as Top5RanksCombinedRevenue_Million,
    cast(
        Top5RanksCombinedRevenueContributionPercent
        as decimal(6, 2)
    ) as Top5RanksCombinedRevenueContributionPercent
from Top5RevenueRankEmployees
order by
    EmployeeRevenueRank,
    EmpKey;

/*==============================================================
  Q14 Business Insight
  --------------------------------------------------------------
  E12 generated the highest total revenue in 2011, producing
  40.99 million and contributing 6.93% of annual sales revenue.

  E15 ranked second with 39.96 million, followed by E01 with
  39.70 million.

  E06 and E04 ranked fourth and fifth with 39.63 million and
  39.51 million, respectively.

  Unlike the order-volume ranking in Q13, no revenue ties
  occurred within the top five rank positions. Therefore, the
  top five revenue ranks included exactly five employees.

  These employees collectively generated 199.80 million,
  representing 33.77% of total revenue in 2011.

  Revenue contribution among the top five employees ranged only
  from 6.68% for E04 to 6.93% for E12.

  The revenue difference between the first-ranked and
  fifth-ranked employees was only 1.48 million.

  This relatively narrow range indicates that revenue generation
  was balanced among the leading employees and that no individual
  employee strongly dominated annual sales.

  E12 achieved the highest average revenue per order among the
  top revenue employees at 8,294.99.

  E01 ranked third in revenue despite processing only 4,798
  orders, fewer than every other employee in the top five. Its
  strong average revenue per order of 8,273.97 helped compensate
  for its lower order volume.

  E06 ranked first in order volume in Q13 but only fourth in
  revenue because its average revenue per order was lower at
  7,992.45.

  Four employees appeared in both the leading order-volume group
  and the top five revenue ranking: E12, E15, E06, and E04.

  These results demonstrate that high order volume supports
  revenue generation but does not independently determine
  revenue rank. The financial value of each order also materially
  affects employee revenue performance.
==============================================================*/

/*==============================================================
  Q14.1 Employee Order Volume vs Revenue Performance in 2011
  --------------------------------------------------------------
  Business Question:
  How do employee rankings based on order volume compare with
  their rankings based on total revenue in 2011?

  Objective:
  Compare both rankings for every employee, identify employees
  associated with higher-value orders, and distinguish
  operational volume from financial performance.
==============================================================*/

-- Calculate order, customer, quantity, and revenue performance
-- for every employee during 2011.
;with EmployeePerformance2011 as
(
    select
        c.Year,
        s.EmpKey,
        count(distinct s.Invoice) as TotalOrders,
        count(distinct s.CustomerKey) as DistinctCustomers,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    where c.Year = 2011
    group by
        c.Year,
        s.EmpKey
),

-- Rank employees separately by order volume and revenue and
-- calculate supporting performance measures.
EmployeeDualRanking as
(
    select
        Year,
        EmpKey,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalOrders desc
        ) as OrderRank,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as RevenueRank,
        TotalOrders * 100.0
            / nullif(
                sum(TotalOrders) over
                (
                    partition by Year
                ),
                0
            ) as OrderContributionPercent,
        TotalRevenue * 100.0
            / nullif(
                sum(TotalRevenue) over
                (
                    partition by Year
                ),
                0
            ) as RevenueContributionPercent,
        TotalRevenue * 1.0
            / nullif(TotalOrders, 0)
            as AverageRevenuePerOrder,
        TotalOrders * 1.0
            / nullif(DistinctCustomers, 0)
            as AverageOrdersPerCustomer,
        TotalQuantitySold * 1.0
            / nullif(TotalOrders, 0)
            as AverageUnitsPerOrder
    from EmployeePerformance2011
),

-- Compare order and revenue rankings and classify each
-- employee's performance pattern.
EmployeeRankComparison as
(
    select
        Year,
        EmpKey,
        OrderRank,
        RevenueRank,
        OrderRank - RevenueRank as RevenueRankImprovement,
        abs(OrderRank - RevenueRank) as AbsoluteRankGap,
        case
            when RevenueRank < OrderRank
                then 'Stronger Revenue Position'
            when OrderRank < RevenueRank
                then 'Stronger Order Volume Position'
            else 'Aligned Rankings'
        end as PerformancePattern,
        TotalOrders,
        DistinctCustomers,
        TotalQuantitySold,
        TotalRevenue,
        OrderContributionPercent,
        RevenueContributionPercent,
        AverageRevenuePerOrder,
        AverageOrdersPerCustomer,
        AverageUnitsPerOrder
    from EmployeeDualRanking
)

-- Return the order and revenue ranking comparison for all
-- employees.
select
    Year,
    EmpKey,
    OrderRank,
    RevenueRank,
    RevenueRankImprovement,
    AbsoluteRankGap,
    PerformancePattern,
    TotalOrders,
    cast(
        OrderContributionPercent
        as decimal(6, 2)
    ) as OrderContributionPercent,
    DistinctCustomers,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        RevenueContributionPercent
        as decimal(6, 2)
    ) as RevenueContributionPercent,
    cast(
        AverageRevenuePerOrder
        as decimal(12, 2)
    ) as AverageRevenuePerOrder,
    cast(
        AverageOrdersPerCustomer
        as decimal(10, 2)
    ) as AverageOrdersPerCustomer,
    cast(
        AverageUnitsPerOrder
        as decimal(8, 2)
    ) as AverageUnitsPerOrder
from EmployeeRankComparison
order by
    AbsoluteRankGap desc,
    EmpKey;

/*==============================================================
  Q14.1 Business Insight
  --------------------------------------------------------------
  Employee order-volume and revenue rankings differed across the
  entire team in 2011.

  Six employees had a stronger revenue position than order-volume
  position, while nine had a stronger order-volume position.
  No employee had exactly aligned order and revenue ranks.

  E01 demonstrated the largest positive revenue-rank improvement.
  The employee ranked 13th in order volume but third in revenue,
  producing a positive rank improvement of 10 positions.

  E01 generated 39.70 million from 4,798 orders and achieved an
  average revenue per order of 8,273.97, the second-highest
  average among all employees.

  E03 showed the largest movement in the opposite direction. The
  employee ranked fifth in order volume but 15th in revenue,
  producing a negative rank difference of 10 positions.

  E03 recorded the lowest average revenue per order at 7,936.34
  and the lowest total revenue at 38.86 million.

  E02 and E05 also had substantially stronger order positions
  than revenue positions, with rank differences of eight and
  seven positions respectively.

  E12 demonstrated the strongest balanced financial performance.
  The employee ranked second in order volume and first in revenue,
  while recording the highest average revenue per order at
  8,294.99.

  E06 processed the highest number of orders but ranked fourth
  in revenue because its average revenue per order was lower
  than those of the leading revenue employees.

  Although some rank differences were large, the underlying
  monetary differences were relatively narrow.

  Total employee revenue ranged from 38.86 million to 40.99
  million, a difference of only 2.13 million.

  Revenue contribution ranged from 6.57% to 6.93%, while order
  contribution ranged from 6.54% to 6.76%.

  Average revenue per order ranged from 7,936.34 to 8,294.99,
  a difference of 358.65.

  Average orders per customer ranged only from 2.29 to 2.41,
  and average units per order remained between 1.00 and 1.02.

  Therefore, large differences in ordinal rank should not be
  interpreted as equally large differences in actual employee
  performance.

  The results demonstrate that revenue rank depends on both
  order volume and the financial value of the orders associated
  with each employee.
==============================================================*/

/*==============================================================
  Employee Analysis Summary
  --------------------------------------------------------------
  - The dataset contained 15 employees with sales activity during
    2011.

  - E06 processed the highest number of distinct orders, handling
    4,959 orders and contributing 6.76% of annual order activity.

  - Because of tied order totals, the top five order ranks
    included seven employees.

  - These seven employees collectively processed 34,494 orders,
    representing 47.05% of annual order activity.

  - E12 generated the highest total revenue at 40.99 million and
    contributed 6.93% of annual revenue.

  - The top five revenue employees collectively generated
    199.80 million, representing 33.77% of annual revenue.

  - E12 also achieved the highest average revenue per order at
    8,294.99.

  - E01 ranked 13th in order volume but third in revenue,
    demonstrating the largest positive revenue-rank improvement.

  - E03 ranked fifth in order volume but 15th in revenue,
    demonstrating the largest difference in favor of order
    volume.

  - Employee revenue ranged from 38.86 million to 40.99 million,
    while order totals ranged from 4,798 to 4,959.

  - Revenue and order contributions were distributed relatively
    evenly across the employee team.

  - Large rank differences did not represent equally large
    differences in actual revenue or order activity.

  - Order volume and average order value both affected employee
    revenue rankings.

  - Employee information was limited to EmpKey because the
    dataset did not contain a separate employee dimension table.
==============================================================*/


/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Use a balanced employee-performance framework that includes
     order volume, revenue, average order value, customer reach,
     profitability, and service quality.

  2. Do not use rank position alone for employee evaluations.
     Small numerical differences can create large changes in
     ordinal rankings.

  3. Examine the customer and product mix associated with E12
     and E01 to identify factors connected with higher-value
     orders.

  4. Review whether employees with stronger order-volume
     positions have appropriate opportunities to work with
     higher-value products or customer accounts.

  5. Maintain the relatively balanced distribution of order
     activity to reduce employee workload concentration.

  6. Consider customer assignments, sales territories, product
     availability, order complexity, and pricing differences
     before comparing employee performance.

  7. Evaluate profit contribution in addition to revenue because
     high-revenue orders may not always generate high profit.

  8. Include customer retention, satisfaction, and repeat-order
     outcomes before using these results for compensation,
     promotion, or performance-management decisions.

  9. Create or import an employee dimension table containing
     employee names, teams, roles, territories, and employment
     status to support more informative future analysis.

  10. Monitor employee metrics across multiple years before
      concluding that the 2011 performance patterns are stable
      or repeatable.
==============================================================*/


/*==============================================================
  End of 04_08_Employee_Analysis.sql
==============================================================*/

set nocount off;