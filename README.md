# Bicycle Manufacturer Sales & Operations Analysis | SQL

![BigQuery](https://img.shields.io/badge/Google%20BigQuery-SQL%20Analysis-4285F4?style=for-the-badge&logo=googlebigquery&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Business%20Analytics-336791?style=for-the-badge)
![Dataset](https://img.shields.io/badge/Dataset-AdventureWorks%202019-F2C94C?style=for-the-badge)

## Overview

This project analyzes sales, inventory, purchasing, discount, territory, and customer retention performance for a bicycle manufacturer using SQL in Google BigQuery.

The analysis is based on the AdventureWorks 2019 dataset and focuses on practical business questions related to product performance, year-over-year growth, sales territory ranking, seasonal discount cost, customer retention behavior, stock movement, stock-to-sales ratio, and pending purchase orders.

## Objective

Use SQL to analyze sales, inventory, purchasing, discount, territory, and customer retention data, then turn operational records into clear business insights for sales planning, inventory control, promotion review, and procurement monitoring.

## Dataset

This project uses the `adventureworks2019` dataset in BigQuery.

The analysis combines data from sales, production, product, discount, and purchasing tables.

| Table | Description |
| --- | --- |
| `Sales.SalesOrderDetail` | Sales order line items, order quantity, product ID, unit price, line total, and special offer ID. |
| `Sales.SalesOrderHeader` | Order-level information such as customer, territory, order status, and order date. |
| `Production.Product` | Product details and product subcategory mapping. |
| `Production.ProductSubcategory` | Product subcategory names. |
| `Sales.SpecialOffer` | Discount type and discount percentage. |
| `Production.WorkOrder` | Production and stock quantity data. |
| `Purchasing.PurchaseOrderHeader` | Purchase order status and total value. |

## Repository Structure

```text
Bicycle_Manufacturer_Sales_Operations_Analysis_SQL/
|-- Bicycle Manufacturer Sales & Operations Analysis.sql
`-- README.md
```

## Analysis Workflow

### 1. Sales Performance by Subcategory

Calculate item quantity, sales value, and order quantity by product subcategory in the last 12 months.
<img width="1221" height="785" alt="image" src="https://github.com/user-attachments/assets/2e7be11d-1d62-4d56-af66-2b44b0075176" />

**Main output:** Monthly subcategory sales performance.

### 2. Year-over-Year Growth Analysis

Calculate YoY quantity growth by subcategory and identify the top 3 fastest-growing subcategories.

**Main output:** Top growth categories based on quantity sold.

### 3. Territory Ranking

Rank the top 3 sales territories by order quantity for each year using `DENSE_RANK`.

**Main output:** Yearly top-performing territories.

### 4. Seasonal Discount Cost

Calculate total seasonal discount cost by subcategory using order quantity, discount percentage, and unit price.

**Main output:** Discount cost by year and subcategory.

### 5. Customer Retention Cohort

Analyze retention behavior for customers with successfully shipped orders in 2014.

**Main output:** Customer count by first purchase month and month difference.

### 6. Monthly Stock Trend

Track monthly stock level by product in 2011 and calculate month-over-month percentage change.

**Main output:** Product-level stock trend and stock volatility.

### 7. Sales-to-Stock Ratio

Compare monthly sales quantity with stock quantity by product in 2011.

**Main output:** Products where demand is close to or higher than available stock.

### 8. Pending Purchase Orders

Calculate the number and total value of pending purchase orders in 2014.

**Main output:** Pending purchasing workload and financial value.

## Analytics

Each analysis includes the business question, SQL logic, result screenshot, and key insight.

SQL script: `Bicycle Manufacturer Sales & Operations Analysis.sql`

| No. | Analysis Area | Business Question | Main Output |
| --- | --- | --- | --- |
