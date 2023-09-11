WITH suspects AS
(SELECT person_id, COUNT(DISTINCT date) as times_attended
  FROM facebook_event_checkin
  WHERE date LIKE '201712%'
  GROUP BY person_id
HAVING times_attended >= 3)

SELECT *
FROM drivers_license
INNER JOIN person
ON person.license_id = drivers_license.id
INNER JOIN suspects
ON suspects.person_id = person.id
WHERE gender = 'female' 
AND hair_color = 'red'
AND car_make LIKE 'Tesla%'