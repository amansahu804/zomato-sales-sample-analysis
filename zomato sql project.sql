--portfolio project on zomato

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'22-09-2017'),
(3,'21-04-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'02-09-2014'),
(2,'15-01-2015'),
(3,'11-04-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'19-04-2017',2),
(3,'18-12-2019',1),
(2,'20-07-2020',3),
(1,'23-10-2019',2),
(1,'19-03-2018',3),
(3,'20-12-2016',2),
(1,'09-11-2016',1),
(1,'20-05-2016',3),
(2,'24-09-2017',1),
(1,'11-03-2017',2),
(1,'11-03-2016',1),
(3,'10-11-2016',1),
(3,'07-12-2017',2),
(3,'15-12-2016',2),
(2,'08-11-2017',2),
(2,'10-09-2018',3);


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
select * from users;

-- what is the total amount each customer spent on zomato?

select s.userid,sum(p.price) total_amount from sales s inner join product p on s.product_id=p.product_id
group by userid order by userid;

--how many days has each zomato customer visited zomato?

select userid,count(distinct created_date) distinct_days  from sales group by userid order by userid;

--what was the first product purchased by the each customer?

select * from
(select *,rank() over(partition by userid order by created_date) rnk from sales) a where rnk=1;

--what is the most item in the menu and how many times was it purchased by all customers?

select userid,count(userid) from sales where product_id=
(select product_id purchase_times from sales group by product_id order by count(product_id) desc limit 1) group by userid;

--which item was most popular for the each customers?

select * from
(select *,rank() over(partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id)a)b
where rnk=1

--which item was purchased by the customer after they became member?

select * from
(select *,rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b on 
a.userid=b.userid where a.created_date >= b.gold_signup_date)a)b where rnk =1

--which iteam was purchased just befor the customer became the member?

select * from
(select *,rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b on 
a.userid=b.userid where a.created_date<= b.gold_signup_date)a)b where rnk=1

--what is the total orders and amount spent for each member before they became a member?

select a.userid,count(a.product_id) total_order,sum(price) amt_spent from
(select a.userid,a.product_id from sales a inner join goldusers_signup b on 
a.userid=b.userid where a.created_date<= b.gold_signup_date)a inner join product b on a.product_id=b.product_id 
group by a.userid order by userid;

--if buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points
--for eg p1 5rs=1zomato point ,for p2 10rs =5 zomato point and p3 5rs=1 zomato point

--calculate points collected by each customers and for which product most points have been given till now?

select userid,sum(total_points*2.5) total_money_earned from
(select e.*,total_price/points total_points from
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select userid,product_id,sum(price) total_price from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c group by userid,product_id) d) e)f
group by userid order by userid

select product_id,sum(total_points) total_point from
(select e.*,total_price/points total_points from
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select userid,product_id,sum(price) total_price from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c group by userid,product_id) d) e)f
 group by product_id order by sum(total_points) desc limit 1

select * from
(select product_id,sum(total_points) total_point,rank() over(order by sum(total_points) desc) rnk from
(select e.*,total_price/points total_points from
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select userid,product_id,sum(price) total_price from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c group by userid,product_id) d) e)f
group by product_id)f where rnk=1



-- In the first one year after a customer joins the gold program (including their join date) irrespective of what the
--customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 and 3 and what was their points 
--earnings in their first year?


select b.*,c.price*0.5 total_points from
(select a.* from
(select * from sales a inner join goldusers_signup b on a.userid=b.userid)a where created_date>=gold_signup_date and 
created_date<=gold_signup_date + interval '1 year')b inner join product c on b.product_id=c.product_id

--rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as na

select e.*,case when rnk='0' then 'na' else rnk end as rnk from
(select c.*,cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end)
as varchar) as rnk from(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a 
left join goldusers_signup b on a.userid=b.userid and a.created_date >= b.gold_signup_date)c)e
