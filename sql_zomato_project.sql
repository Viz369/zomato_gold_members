drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,str_to_date('09-22-2017','%m-%d-%Y')),
(3,str_to_date('04-21-2017','%m-%d-%Y'));

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,str_to_date('09-02-2014','%m-%d-%Y')),
(2,str_to_date('01-15-2015','%m-%d-%Y')),
(3,str_to_date('04-11-2014','%m-%d-%Y'));

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,str_to_date('04-19-2017','%m-%d-%Y'),2),
(3,str_to_date('12-18-2019','%m-%d-%Y'),1),
(2,str_to_date('07-20-2020','%m-%d-%Y'),3),
(1,str_to_date('10-23-2019','%m-%d-%Y'),2),
(1,str_to_date('03-19-2018','%m-%d-%Y'),3),
(3,str_to_date('12-20-2016','%m-%d-%Y'),2),
(1,str_to_date('11-09-2016','%m-%d-%Y'),1),
(1,str_to_date('05-20-2016','%m-%d-%Y'),3),
(2,str_to_date('09-24-2017','%m-%d-%Y'),1),
(1,str_to_date('03-11-2017','%m-%d-%Y'),2),
(1,str_to_date('03-11-2016','%m-%d-%Y'),1),
(3,str_to_date('11-10-2016','%m-%d-%Y'),1),
(3,str_to_date('12-07-2017','%m-%d-%Y'),2),
(3,str_to_date('12-15-2016','%m-%d-%Y'),2),
(2,str_to_date('11-08-2017','%m-%d-%Y'),2),
(2,str_to_date('09-10-2018','%m-%d-%Y'),3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;



/* Q1: What is the total amount each customer spent on zomato?*/

select s.userid, sum(p.price) as amount_spent 
from sales s left join product p  
on s.product_id = p.product_id
group by s.userid
order by amount_spent desc;

/* Q2: How many days has each customer visited Zomato?*/

select userid, count(distinct created_date ) as num_visits 
from sales 
group by userid;

/* Q3: What was the first product purchased by each customer?*/

select userid,product_id from(select *, rank() over(partition by userid order by created_date) as rnk
from sales ) as a
where rnk=1;

/* Q4: What is the most purchased item on the menu and
 how many times was it purchased by each customer?*/
 
 with recursive most_bought_product as (
 select product_id,count(*)as num_sold from sales
 group by product_id
 order by num_sold desc
 limit 1) 
 select s.userid , count(s.product_id) as times_Purchased 
 from sales s join most_bought_product mbp
 on s.product_id = mbp.product_id
 group by s.userid
 order by s.userid;
 
 -- ALTERNATE SOLUTION
 
 select userid,count(product_id) as cnt from sales where product_Id =
 (select  product_id from sales group by product_id order by count(product_id) desc limit 1)
 group by userid;
 
 /* Q5: Which item was the most popular for each customer?*/
 
 select userid,product_id from(
 select userid, product_Id, count(*) as cnt ,
rank() over(partition by userid order by count(*) desc) as rnk
from sales group by userid,product_id
)as a where rnk=1;

/* Q6: Which item was first purchased by a customer after they became a member?*/

select* from(select userid, product_Id,
rank() over(partition by userid order by created_date) as rnk from
(select s.userid, s.product_id,s.created_date,g.gold_signup_date 
from sales s join goldusers_signup g 
on s.userid  = g.userid and s.created_date>=g.gold_signup_date) as c ) as d
where rnk=1;

/*Q7: Which item was purchased by customer just befor they became a member?*/

select* from(select userid, product_Id,
rank() over(partition by userid order by created_date desc) as rnk from
(
select s.userid, s.product_id,s.created_date,g.gold_signup_date 
from sales s join goldusers_signup g 
on s.userid  = g.userid and s.created_date<g.gold_signup_date
) as c ) as d
where rnk=1;

/*Q8: What is the total no. of orders placed and amount spent by each customer
      before becoming a member?*/
      
select c.userid, count(c.product_id) as cnt, sum(p.price) as amount from
(
select s.userid, s.product_id,s.created_date,g.gold_signup_date 
from sales s join goldusers_signup g 
on s.userid  = g.userid and s.created_date<g.gold_signup_date
) as c join product p on c.product_id =p.product_id
group by c.userid;

/*Q9: Buying each product generates certain points on zomato where 5rs = 2 Zomato points
and each product has different points . For p1 5rs = 1 point, p2 10rs = 5 points,
p3 5rs = 1 point, based on this information , calculate the point collected by each customer
and for which product most points have been given.*/

select userid,ceiling(sum(total_spent/amount)*2.5) as cashback_earned from
(select c.*, (case when product_id = 1 then 5 
              when product_id =2 then 2 
              when product_Id = 3 then 5  else 0 end) as amount 
              from(select s.userid,s.product_id, sum(p.price) as total_spent
from sales s join product p 
on s.product_id  = p.product_id
group by s.userid,s.product_id
order by s.userid,s.product_id) as c) as d
group by userid;


select product_id, ceiling(sum(total_spent/amount)) as points from
(select c.*, (case when product_id = 1 then 5 
              when product_id =2 then 2 
              when product_Id = 3 then 5  else 0 end) as amount 
              from(select s.userid,s.product_id, sum(p.price) as total_spent
from sales s join product p 
on s.product_id  = p.product_id
group by s.userid,s.product_id
order by s.userid,s.product_id) as c) as d group by product_id;

/* Q10: In the 1st year(including joining_dATE) after a customer joins the gold membership
a customer earns 5 zomato points for every 10rs spent . Who earned more points 1 or 3
and how many points did each of them earn?*/


select c.* 
              from(select s.userid, ceiling(sum(p.price)/2 )as total_points
from sales s join product p 
on s.product_id  = p.product_id
join goldusers_signup g on g.userid = s.userid
and s.created_date >=g.gold_signup_date
where s.created_date < date_add(g.gold_signup_date, interval 365 day)
group by s.userid
order by s.userid) as c;

/*Q11: Rank all the transactions of the customers based on order date*/

select e.*, case when rnk = 0 then 'na' else rnk end as rnkk from
(select *, rank() over(partition by userid order by created_date) as rnk
from sales;

/* Q12: Rank all the transactions for each member after they became a zomato gold member
for every non gold member transaction mark as na. */

select e.*, case when rnk = 0 then 'na' else rnk end as rnkk from
 (select c.*, (case when gold_signup_date is null then 0 else 
 rank() over(partition by userid order by created_date desc) 
 end)  as rnk 
from (select s.userid,s.product_id,s.created_date, g.gold_signup_date
from sales s left join goldusers_signup g 
on s.userid = g.userid and s.created_date>=g.gold_signup_date
group by 1,2,3,4
order by s.userid) as c) as e;