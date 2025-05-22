SET search_path TO bookings


--1. Сколько суммарно каждый тип самолета провел в воздухе, если брать завершенные перелеты
SELECT a.model, sum(f.actual_arrival - f.actual_departure)
FROM aircrafts a
JOIN flights f ON a.aircraft_code = f.aircraft_code
WHERE f.status = 'Arrived'
GROUP BY a.model
ORDER BY sum DESC


--2. Сколько было получено посадочных талонов по каждой брони
SELECT b.book_ref, count(DISTINCT bp.boarding_no)
FROM bookings b
LEFT JOIN tickets t ON b.book_ref = t.book_ref
LEFT JOIN boarding_passes bp ON t.ticket_no = bp.ticket_no
GROUP BY b.book_ref
ORDER BY count(DISTINCT bp.boarding_no) DESC


--3. Вывести общую сумму продаж по каждому классу перелета
SELECT tf.fare_conditions, sum(tf.amount)
FROM ticket_flights tf 
GROUP BY tf.fare_conditions
ORDER BY sum(tf.amount) DESC


--4. Найти маршрут с наибольшим финансовым оборотом
SELECT f.departure_airport, f.arrival_airport, sum(tf.amount)
FROM flights f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY f.departure_airport, f.arrival_airport
ORDER BY sum(tf.amount) DESC
LIMIT 1


--5. Найти наилучший и наихудший месяц по бронированию билетов (количество и сумма)
WITH cte AS (
	SELECT date_trunc('month', b.book_date) AS month, 
	       count(b.book_ref) AS count, 
	       sum(b.total_amount) AS sum 
	FROM bookings b 
	GROUP BY date_trunc('month', b.book_date))
	SELECT month, count, sum
	FROM cte
	WHERE (count = (SELECT max(count) FROM cte) AND sum = (SELECT max(sum) FROM cte))
	   OR (count = (SELECT min(count) FROM cte) AND sum = (SELECT min(sum) FROM cte))


--6. Между какими городами пассажиры не делали пересадки? Пересадкой считается нахождение пассажира в промежуточном аэропорту менее 24 часов
WITH AllCities AS (
		SELECT
			a1.city AS city_1,
			a2.city AS city_2
		FROM airports a1
		CROSS JOIN airports a2
		WHERE a1.city < a2.city		
		),
	Flights AS (
		SELECT DISTINCT
        	f.departure_city,
			f.arrival_city,
			tf.ticket_no,
			f.actual_departure AS dep_time,
			f.actual_arrival AS arr_time
		FROM flights_v f
		JOIN ticket_flights tf ON tf.flight_id = f.flight_id
		),
	Transfers AS (
		SELECT DISTINCT
			ft1.departure_city AS dep_city_1,
			ft1.arrival_city AS arr_city_1,
			ft2.departure_city AS dep_city_2,
			ft2.arrival_city AS arr_city_2
		FROM Flights ft1
		JOIN Flights ft2 ON ft1.ticket_no = ft2.ticket_no
						AND ft1.arrival_city = ft2.departure_city
						AND ft1.arr_time < ft2.dep_time
						AND ft2.dep_time - ft1.arr_time < '24 hours'
		)
SELECT city_1, city_2
FROM AllCities
EXCEPT
SELECT DISTINCT dep_city_1, arr_city_2
FROM Transfers
ORDER BY city_1, city_2