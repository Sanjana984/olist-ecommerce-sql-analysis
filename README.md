# Olist E-Commerce — SQL Forensic Analysis

## Overview
End-to-end forensic SQL analysis of 100,000+ real orders from Olist, 
Brazil's largest e-commerce marketplace. Built entirely in MySQL from 
scratch — schema design, data import, cleaning, and 17 advanced queries 
across 5 business chapters.

---

## Key Findings

| Finding | Value |
|---|---|
| Gross revenue analysed | $13.59M |
| Revenue lost to cancellations | $95,235 |
| Revenue stuck in pipeline | $121,965 |
| Customer retention rate | 6.44% (industry avg 20–30%) |
| High value customers gone cold | 1,572 customers |
| Dormant repeat revenue opportunity | $1.48M |
| On time delivery rate | 91.89% |
| Worst delivery delay | 188 days |
| High risk instalment exposure | $2.33M |

---

## Project Structure

### Chapter 1 — Revenue Leakage
- Order status breakdown
- Revenue at risk by status
- Seller cancellation ranking
- Freight vs product margin analysis
- Late delivery performance scorecard

### Chapter 2 — Customer Lifetime Value
- RFM scoring (Recency, Frequency, Monetary)
- Customer segmentation — Champions, Loyal, At Risk, Lost
- Cohort retention analysis
- Overall retention rate verification

### Chapter 3 — Seller Performance Benchmarking
- Seller metrics by category
- Hidden gem and underperformer detection
- Seller classification summary

### Chapter 4 — Payment Behaviour and Credit Risk
- Payment type breakdown
- Instalment count vs satisfaction correlation
- Credit risk proxy scoring model

### Chapter 5 — Executive Summary
- Master KPI dashboard
- 8 business recommendations with evidence and impact

---

## SQL Concepts Used
CTEs · Multi-table JOINs · CASE WHEN · Subqueries · 
GROUP BY · HAVING · DATEDIFF · DATE_FORMAT · 
Aggregate functions · UNION ALL · RFM segmentation

---

## Files
| File | Description |
|---|---|
| `olist_analysis.sql` | All 17 queries with comments |
| `olist_dashboard.html` | Visual KPI dashboard — open in any browser |

---

## Dataset
[Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
1.6 million rows across 8 tables

## Tools
MySQL 9.3 · MySQL Workbench · HTML/CSS

---
*Portfolio project — targeting Business Analyst and Data Analyst roles*
