/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/

select * from customer_t;
select * from order_t;
select * from product_t;
select * from shipper_t;

/*-- QUESTIONS RELATED TO CUSTOMERS
     
     
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/


select state,count(*) as number_of_customers from customer_t group by state;

#Observation: This inquiry aids in determining the geographic location of New-Wheels' clientele. Understanding regional tastes and wants and implementing specialised marketing strategies might benefit greatly from this.

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/


-- [q2] what is the average rating in each quarter?
-- very bad is 1, bad is 2, okay is 3, good is 4, very good is 5.

select 
    avg(numeric_rating) as avg_rating,
    quarter_number
from (
    select 
        quarter_number,
        case customer_feedback
            when 'Very bad' then 1
            when 'Bad' then 2
            when 'Okay' then 3
            when 'Good' then 4
            else 5 
        end as numeric_rating
    from order_t
) as ratings
group by quarter_number
order by quarter_number;

#Observation: The app's after-sales service feedback is the subject of this query. By calculating average ratings across quarters, it is able to directly show patterns in consumer satisfaction. This is essential for pinpointing areas where customer service has to be improved.

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/


with count_of_feedback as(
select customer_feedback,count(*) as tot_cust_feedback,quarter_number
from order_t 
group by customer_feedback,quarter_number
order by quarter_number),

tot_cust_feedback_per_quarter as (select count(*) as overall_cust_feedback,quarter_number
from order_t 
group by quarter_number)

select customer_feedback,(tot_cust_feedback*100)/overall_cust_feedback as percentage_feedback,cof.quarter_number 
from count_of_feedback cof
join tot_cust_feedback_per_quarter tf
on cof.quarter_number=tf.quarter_number;                         

#Observation: The percentage distribution of the various feedback kinds over the course of quarters is examined in this query. It offers information on whether there is a growing pattern of unfavourable reviews, which can be the reason for a drop in sales.

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

select vehicle_maker,count(*) num_of_customers
from product_t p
join order_t o 
on p.product_id=o.product_id
group by vehicle_maker
order by count(*) desc
limit 5;

#Observation: Marketing plans and inventory management are aided by knowledge of consumer preferences regarding car brands. It helps determine which car brands to highlight and prioritise.

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/


with table_ref as (
select vehicle_maker, state, count(*), RANK() OVER (PARTITION BY state ORDER BY COUNT(c.customer_id) DESC) AS rankk
from product_t p
join order_t o on p.product_id=o.product_id
join customer_t c on o.customer_id=c.customer_id
group by vehicle_maker,state)
select vehicle_maker, state, rankk
from table_ref
where rankk=1;

#Observation: This query includes client preferences for vehicle make and location. It assists in customising product offers to meet local demand, which may increase sales in particular locations.

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/


select count(order_id) as number_of_orders, quarter_number
from order_t
group by quarter_number
order by quarter_number;

#Observation: Order volume tracking over quarters shows total business activity. Reduced order volumes may be a sign of consumer discontent or market saturation, requiring tactical changes.

-- ---------------------------------------------------------------------------------------------------------------------------------


/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/


with table_ref as(
select sum(vehicle_price*quantity*(1-discount)) as sum_of_revenue, quarter_number
from order_t
group by quarter_number)
select 
quarter_number,
((sum(sum_of_revenue)-lag(sum_of_revenue) over (order by quarter_number))/lag(sum_of_revenue) over (order by quarter_number))*100 as qoq_percentage_change
from table_ref
group by quarter_number;
      
#Observation: Trends in revenue are important markers of a company's health. By calculating the percentage change in revenue between quarters, financial planning and forecasting can be guided towards determining whether there is growth or decline.

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

select sum(vehicle_price*quantity*(1-discount)) as sum_of_revenue, count(order_id) as num_of_orders, quarter_number
from order_t
group by quarter_number
order by quarter_number;

#Observation: By merging order volume and revenue patterns, this query offers a thorough perspective. It provides information about whether shifts in order volume or pricing policies are responsible for variations in revenue.							

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

select credit_card_type, avg(discount)
from customer_t c
join order_t o on c.customer_id=o.customer_id
group by credit_card_type;

#Observation: Knowing the typical discounts for various credit card kinds aids in assessing consumer preferences for payment methods. Additionally, it helps to maximise discount tactics in order to increase sales.

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
select quarter_number, avg(datediff(ship_date,order_date)) as avg_time_taken_in_days
from order_t
group by quarter_number
order by quarter_number;


#Observation: Customer satisfaction is directly impacted by shipping time. Finding operational inefficiencies or efficiencies that could impact customer retention can be accomplished by monitoring average shipment times over a period of quarters.


-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



