drop view if exists all_categories;
drop view if exists random_product;
drop view if exists cc_types;
drop function if exists products_in_category;
drop function if exists random_product_in_category;
drop function if exists product_detail;
drop function if exists keyword_search;
drop function if exists add_to_cart;
drop table if exists categories;
drop table if exists products;
drop table if exists creditcard;
drop table if exists customers;
drop table if exists cart;

create table categories(
id integer primary key,
major text not null,
minor text not null);

create view all_categories as
select id as category_id, major as cat_name, 
minor as subcat_name from categories 
order by cat_name, subcat_name;

create table products(
id numeric not null references  categories(id),
product_id text not null primary key,
title text not null,
author text not null,
publisher text not null,
year integer not null,
description text not null,
price numeric check (price>=0),
qtyonhand integer not null check (qtyonhand>=0)
);
create table creditcard(
cc_id text primary key,
cc_type text not null
);

create table customers(
cust_id numeric primary key,
first_name text not null,
last_name text not null,
address text not null,
city text,
state text,
zip text not null,
email text,
cc_num text,  
cc_type text not null references creditcard(cc_id),
username text,
password text
);
create table cart (
cart_id text primary key,
prd_id text not null references products(product_id),
description text not null,
qty integer,
--total numeric
);
	
create view random_product as
select  product_id as product_id, title, author, publisher, year, description, price,
case 
when qtyonhand >=1 then 'Y'
	else 'N'
end as in_stock,
categories.id as category_id, major as cat_name, 
minor as subcat_name 
from products join categories on 
products.id = categories.id 
where qtyonhand >= 1 order by random() limit 1;

create view cc_types as
select c1.cc_id as code, c1.cc_type as name from creditcard c1 inner join 
creditcard c2 on c1.cc_id =c2.cc_id 
-- group by c1.cc_id, c2.cc_type
order by c2.cc_type;


create function products_in_category(integer) returns 
table (product_id text,title text, author text,
publisher text, year integer, description text, price numeric,qtyonhand text, id  numeric, 
major text, minor text ) as $$ 
select products.product_id, products.title, products.author, products.publisher, 
products.year, products.description, products.price, products.qtyonhand case when (qtyonhand >=1) then 'Y' else 'N' end as in_stock , categories.id as category_id, categories.major as cat_name, categories.minor as subcat_name
from products join categories on 
products.id = categories.id 
where  categories.id=$1;
$$language sql;

create function random_product_in_category(integer) returns 
table (product_id text,title text, author text,
publisher text, year integer, description text, price numeric, in_stock text, id numeric,
major text, minor text ) as $$
select products.product_id, products.title, products.author, products.publisher,
products.year, products.description, products.price,  case when (qtyonhand >=1) then 'Y' else 'N' end as in_stock , categories.id as category_id, categories.major as cat_name, categories.minor as subcat_name
from products join categories on
products.id = categories.id
where  categories.id=$1 order by random() limit 1;
$$language sql;

create function product_detail(text) returns
table (product_id text,title text, author text, publisher text, year integer, description text,
 price numeric, qtyonhand text, id  numeric, major text, minor text ) as $$ 
select products.product_id, products.title, products.author, products.publisher,
products.year, products.description, products.price,  case when (qtyonhand >=1) then 'Y' else 'N' end as in_stock ,
categories.id as category_id, categories.major as cat_name, categories.minor as subcat_name
from products join categories on
products.id = categories.id
where  product_id=$1;
$$language sql;


create function keyword_search(text) returns
table (product_id text, title text, author text,
publisher text, year integer, description text, price numeric, in_stock text,
id numeric, major text, minor text ) as $$ 
select products.product_id, products.title, products.author, products.publisher, 
products.year, products.description, products.price, case when (qtyonhand >=1) then 'Y' else 'N'
end as in_stock, categories.id, categories.major, categories.minor
from products join categories on 
products.id = categories.id 
where product_id::text = $1
or title ilike '%'|| $1 ||'%'
or author ilike '%'|| $1 ||'%'
or description ilike'%'|| $1 ||'%';
$$language sql;

----**********not working*********---
create function add_to_cart(text,text) returns void AS $$
insert into cart(cart_id, description, prd_id, qty, products.price) values (select cart.cart_id,
cart.description,cart.prd_id, cart.qty, products.price from cart, products)where cart_id=$1;

update products
set qtyonhand = qtyonhand - 1 
where product_id =$2;
select qtyonhand from products where product_id =$2;
--from products join cart on prd_id=product_id 
--where cart_id = $1 and product_id = $2;
$$ language sql;

create function cart_contents(text) returns table (product_id text, title text, price numeric,
qty integer, total numeric, rtotal numeric)as $$
select products.product_id, products.title, products.price, cart.qty,
(products.price * cart.qty) as total
--(select sum(total) from cart c where Cin.cart_id<= Cout.cart_id )as running_total from
--cart Cout order by cart_id)
from products join cart on prd_id = product_id
where cart_id = $1 group by products.product_id, cart.qty;
$$ language sql;

create function create_customer(text,text,text,text,text,text,
text,text,text,text,text) returns table 
(first_name text, last_name text, address text,
city text, state text, zip text, email text, cc_num text, cc_type text, username text,password text
 as $$
select first_name,last_name, address, city, state,zip,email, cc_num,cc_type,
username, password from customers;
$$ language sql;


insert into categories values (101, 'Book', 'Computer');
insert into categories values (102, 'Book', 'Biography');
insert into categories values (103, 'Book', 'Novel');
insert into categories values (104, 'Book', 'Fictional');
insert into categories values (105, 'Book', 'Encyclopedias');
insert into categories values (201, 'Movies', 'Action');
insert into categories values (202, 'Movies', 'Drama');
insert into categories values (203, 'Movies', 'Comdey');
insert into categories values (204, 'Movies', 'Mockumentaries');
insert into categories values (205, 'Movies', 'Thriller');
insert into categories values (301, 'Music', 'Classical');
insert into categories values (302, 'Music', 'Country');
insert into categories values (303, 'Music', 'Rock');
insert into categories values (304, 'Music', 'Holiday');
insert into categories values (305, 'Music', 'Jazz');

\copy products from products.csv csv

insert into creditcard values ('V', 'Visa');
insert into creditcard values ('M', 'Master');
insert into creditcard values ('D', 'Discover');
insert into creditcard values ('A', 'American Express');
