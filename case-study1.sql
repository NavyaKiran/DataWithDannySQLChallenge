select * from dannys_diner.sales; 
select * from dannys_diner.members; 
select * from dannys_diner.menu; 

--What is the total amount each customer spent at the restaurant?

select dannys_diner.sales.customer_id, sum(dannys_diner.menu.price)
from dannys_diner.sales left join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
group by dannys_diner.sales.customer_id;

--How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as number_of_days 
from dannys_diner.sales 
group by customer_id;

--What was the first item(s) from the menu purchased by each customer?
select distinct customer_id, product_name
from 
(select customer_id, order_date, product_id, rank() over(partition by customer_id order by order_date) as rn 
from dannys_diner.sales) temp left join dannys_diner.menu on temp.product_id = dannys_diner.menu.product_id
where rn = 1
order by customer_id

--What is the most purchased item on the menu and how many times was it purchased by all customers?

select dannys_diner.sales.product_id, count(dannys_diner.sales.product_id) as num_times, product_name
from dannys_diner.sales inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
group by dannys_diner.sales.product_id, dannys_diner.menu.product_name
order by num_times desc 
limit 1;

--Which item(s) was the most popular for each customer?
with cte as (select customer_id, product_id, cnt, rank() over(partition by customer_id order by cnt) as rn
from 
(select dannys_diner.sales.customer_id, dannys_diner.sales.product_id, count(dannys_diner.sales.product_id) as cnt
from dannys_diner.sales
group by dannys_diner.sales.customer_id, dannys_diner.sales.product_id) temp) 

select cte.customer_id, dannys_diner.menu.product_name, cnt 
from cte inner join dannys_diner.menu on cte.product_id = dannys_diner.menu.product_id
where rn = 1
order by customer_id;

--Which item was purchased first by the customer after they became a member and what date was it? (including the date they joined)
with cte as (select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id
from dannys_diner.sales inner join dannys_diner.members on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
where dannys_diner.sales.order_date >= dannys_diner.members.join_date)

select customer_id, order_date, product_name 
from 
(select customer_id, order_date, product_name, rank() over(partition by customer_id order by order_date) as rn
from cte inner join dannys_diner.menu on cte.product_id = dannys_diner.menu.product_id) temp 
where rn = 1;

--Which menu item(s) was purchased just before the customer became a member and when?

with cte as (select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id
from dannys_diner.sales inner join dannys_diner.members on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
where dannys_diner.sales.order_date < dannys_diner.members.join_date)

select customer_id, order_date, product_name 
from 
(select customer_id, product_id, order_date, rank() over(partition by customer_id order by order_date desc) as rn 
from cte) temp 
inner join dannys_diner.menu on temp.product_id = dannys_diner.menu.product_id
where rn = 1
order by customer_id;

--What is the number of unique menu items and total amount spent for each member before they became a member?

select dannys_diner.sales.customer_id, count(distinct(dannys_diner.sales.product_id)) as unique_items, sum(price) as total_spend
from dannys_diner.sales inner join dannys_diner.members 
on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
where order_date < join_date
group by dannys_diner.sales.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(case when product_name = 'sushi' then price * 20 else 10 * price end) as points 
from 
(select dannys_diner.sales.customer_id, dannys_diner.sales.product_id, dannys_diner.menu.product_name, dannys_diner.menu.price
from dannys_diner.sales inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id) temp 
group by customer_id
order by points desc;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select customer_id, sum(case 
when order_date between join_date and (join_date + INTERVAL '6 days') then 2*price*10 
when product_name = 'sushi' then price*20 
else price*10 end) as points
from 
(select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id, 
dannys_diner.members.join_date, dannys_diner.menu.product_name, dannys_diner.menu.price
from dannys_diner.sales inner join dannys_diner.members on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
where date_trunc('month', order_date) = date'2021-01-01') temp
group by customer_id;

--BONUS QUESTION 11

select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.menu.product_name, 
dannys_diner.menu.price, 
case 
    when dannys_diner.sales.order_date < dannys_diner.members.join_date then 'N' 
    when dannys_diner.sales.order_date >= dannys_diner.members.join_date then 'Y'
    else 'N'
    end as member
from dannys_diner.sales inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
left join dannys_diner.members on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
order by customer_id, order_date, price desc

--BONUS QUESTION 12

with cte as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.menu.product_name, 
dannys_diner.menu.price, 
case 
    when dannys_diner.sales.order_date < dannys_diner.members.join_date then 'N' 
    when dannys_diner.sales.order_date >= dannys_diner.members.join_date then 'Y'
    else 'N'
    end as member
from dannys_diner.sales inner join dannys_diner.menu on dannys_diner.sales.product_id = dannys_diner.menu.product_id
left join dannys_diner.members on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
order by customer_id, order_date, price desc
)

select customer_id, order_date, product_name, price, member, 
case when member = 'N' then null 
     else rank() over(partition by customer_id, member order by order_date, price desc) end as ranking
from cte