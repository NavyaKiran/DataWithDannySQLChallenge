select * from pizza_runner.customer_orders;
select * from pizza_runner.pizza_names;
select * from pizza_runner.pizza_recipes;
select * from pizza_runner.pizza_toppings;
select * from pizza_runner.runner_orders;
select * from pizza_runner.runners;

update pizza_runner.customer_orders
set 
  exclusions = case when exclusions = 'null' then null else exclusions end 
  , extras =  case when extras = 'null' then null else extras end 
  
update pizza_runner.runner_orders 
set 
  distance = case when distance = 'null' then null else distance end, 
  duration = case when duration = 'null' then null else duration end, 
  pickup_time = case when pickup_time = 'null' then null else pickup_time end, 
  cancellation = case when cancellation = 'null' then null else cancellation end
  
update pizza_runner.runner_orders
set
distance = case when distance like '%km' then trim('km' from distance) else distance end 

update pizza_runner.runner_orders 
set 
  duration = case when duration like '%mins' then trim('mins' from duration) 
                  when duration like '%minutes' then trim('minutes' from duration) 
                  when duration like '%minute' then trim('minute' from duration)
                  else duration
              end

ALTER table pizza_runner.runner_orders
alter column pickup_time type date using pickup_time::date

ALTER table pizza_runner.runner_orders
alter column distance type decimal(4,2) using distance::decimal(4,2), 
alter column duration type int using duration::int

-- How many pizzas were ordered?

select count(pizza_id) 
from pizza_runner.customer_orders;

--How many unique customer orders were made?

select count(distinct(order_id)) as unique_order 
from pizza_runner.customer_orders;

--How many successful orders were delivered by each runner?

select runner_id, count(distinct(order_id))
from pizza_runner.runner_orders 
where cancellation is null or cancellation not in ('Restaurant Cancellation', 'Customer Cancellation')
group by runner_id;


--How many of each type of pizza was delivered?

select c.pizza_name, count(a.pizza_id) as pizza_type_count 
from pizza_runner.customer_orders a inner join pizza_runner.runner_orders b on a.order_id = b.order_id 
left join pizza_runner.pizza_names c on a.pizza_id = c.pizza_id 
where b.cancellation is null or b.cancellation not in ('Restaurant Cancellation', 'Customer Cancellation')
group by a.pizza_id, c.pizza_name

--How many Vegetarian and Meatlovers were ordered by each customer?

select a.customer_id,
sum(case when pizza_name = 'Meatlovers' then 1 else 0 end) as Meatlovers, 
sum(case when pizza_name = 'Vegetarian' then 1 else 0 end) as Vegetarian
from pizza_runner.customer_orders a 
inner join pizza_runner.pizza_names b on a.pizza_id = b.pizza_id
group by a.customer_id
order by a.customer_id

--What was the maximum number of pizzas delivered in a single order?

select a.order_id, count(pizza_id) as number_of_pizzas
from pizza_runner.customer_orders a inner join pizza_runner.runner_orders b on a.order_id = b.order_id
where b.cancellation is null or b.cancellation not in ('Restaurant Cancellation', 'Customer Cancellation')
group by a.order_id
order by number_of_pizzas desc
limit 1;

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

with cte as (select customer_id, order_id
case when extras is null or extras = '' then 0 else 1 end as extras, 
case when exclusions is null or exclusions = '' then 0 else 1 end as exclusions
from pizza_runner.customer_orders)

select cte.customer_id, 
sum(case when exclusions = 0 and extras = 0 then 1 else 0 end) as no_change, 
sum(case when exclusions = 1 or extras = 1 then 1 else 0 end) as at_leat_one_change
from cte inner join pizza_runner.runner_orders b on cte.order_id = b.order_id 
where b.cancellation is null or b.cancellation not in ('Restaurant Cancellation', 'Customer Cancellation')
group by cte.customer_id
order by cte.customer_id

--How many pizzas were delivered that had both exclusions and extras?

with cte as (select customer_id, order_id, pizza_id,
case when extras is null or extras = '' then 0 else 1 end as extras, 
case when exclusions is null or exclusions = '' then 0 else 1 end as exclusions
from pizza_runner.customer_orders)

select count(*) 
from cte 
where exclusions = 1 and extras = 1

--What was the total volume of pizzas ordered for each hour of the day?

select date_part('hour', order_time::timestamp) as hour_of_day, 
count(pizza_id) 
from pizza_runner.customer_orders
group by hour_of_day
order by hour_of_day

--What was the volume of orders for each day of the week?

select TO_CHAR(order_time, 'Day') as Day, 
count(pizza_id) 
from pizza_runner.customer_orders
group by date_part('dow', order_time::timestamp), Day

              
