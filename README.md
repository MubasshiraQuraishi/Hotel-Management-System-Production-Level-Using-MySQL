🛎️ **SQL-Based Hotel Management System — End-to-End Project**

I built a complete **Hotel Management System** using **pure SQL** — without any front-end or third-party tools.

✅ This project helped me understand how real-world hotel operations can be managed directly through stored procedures, triggers, and queries.

Here’s what I worked on:

🔹 **Database Design**

* Created normalized tables for `Guests`, `Rooms`, `Bookings`, `Payments`, and `Late Check-outs`.

🔹 **Core SQL Features**

* Designed stored procedures for booking, cancellations, check-ins, and late check-out handling.
* Built custom reports using `JOINs`, `GROUP BY`, and `CASE`.
* Used views for easy payment summaries.

🔹 **Automation with Triggers**

* Automatically updated room availability and prevented double bookings.
* Flagged duplicate guest entries and invalid data.

🔹 **Error Handling & Transactions**

* Used `START TRANSACTION`, `ROLLBACK`, and error handlers to ensure data safety.

🔹 **Dynamic SQL**

* Wrote a procedure where users can pass a column name and value to get filtered bookings dynamically.
[I am getting started with Dynamic SQL]

🔹 **Role-Based Access**

* Created user roles like `Receptionist`, `Manager`, `Accountant` with proper GRANT permissions.

💡 **Key Takeaway**: This project taught me how to write production-level SQL code that’s **safe, reusable, and well-structured**.
