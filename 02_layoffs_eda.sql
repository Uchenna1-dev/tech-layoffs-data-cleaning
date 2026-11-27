---Exploratory Data Analysis
select *
from layoffs.layoffs_staging2;

---find the largest total_laid_off and largest percentage_laid_off
select max(total_laid_off) as maxtotallaidoff, max(percentage_laid_off) as max_percentagelaidoff
from layoffs.layoffs_staging2;

---companies where percentage laid off equals 1
select company, funds_raised_millions, percentage_laid_off
from layoffs.layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc nulls last;

---total layoffs for each company
select company, sum(total_laid_off) as sum_totallaidoff
from layoffs.layoffs_staging2
group by company
order by sum_totallaidoff desc nulls last;

---total layoffs for each industry
select industry, sum(total_laid_off) as sum_totallaidoff
from layoffs.layoffs_staging2
group by industry
order by sum_totallaidoff desc nulls last;

---total layoffs for each country
select country, sum(total_laid_off) as sum_totallaidoff
from layoffs.layoffs_staging2
group by country
order by sum_totallaidoff desc nulls last;

---date range earliest and latest day
select min(date), max(date)
from layoffs.layoffs_staging2;

--total layoffs per year
select extract(year from date) as year, sum(total_laid_off) as total
from layoffs.layoffs_staging2
group by 1
order by year asc nulls last;

--worst months for layoffs
select to_char(date, 'YYYY-MM') as month, sum(total_laid_off) as total
from layoffs.layoffs_staging2
group by month
order by total desc nulls last;

---total laid off per stage
select stage, sum(total_laid_off) as total
from layoffs.layoffs_staging2
group by stage
order by total desc nulls last;

---rolling sum to see the progression of total laid off
with monthly_totals as (
select to_char(date, 'YYYY-MM') as month, sum(total_laid_off) as total
from layoffs.layoffs_staging2
where date is not null
group by 1
)
select month, total, sum(total) over(order by month) as rolling_total
from monthly_totals
order by month;

---which five companies laid off the most people in each year?
with layoffs as (
select extract(year from date) as year, company, sum(total_laid_off) as total
from layoffs.layoffs_staging2
where total_laid_off is not null
group by year, company
),
ranked as (
select year, company, total,
dense_rank() over(partition by year order by total desc) as ranking
from layoffs
)
select *
from ranked
where ranking <= 5
order by year, ranking asc;
