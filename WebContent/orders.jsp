<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.util.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="stylesheet"
	href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
	integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7"
	crossorigin="anonymous">
<title>CSE135 Project</title>
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
	<script type="text/javascript" src="case1_js.js"></script>
</head>
<%
	Connection conn = null;
String orderName = " ORDER BY name ";
String orderState = " ORDER BY state ";
String orderTopK = " ORDER BY totals desc";
String productOrder = orderName;
String stateOrder = orderState;
String salesCategory = "";
String salesCategoryMenu = "";
	try {
		Class.forName("org.postgresql.Driver");
	    String url = "jdbc:postgresql://localhost:5433/cse135pt3";
	    String admin = "postgres";
	    String password = "alin";
  	conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	
	
	
	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String action = request.getParameter("submit");
		if (action.equals("insert")) {
	int queries_num = Integer.parseInt(request.getParameter("queries_num"));
	Random rand = new Random();
	int random_num = rand.nextInt(30) + 1;
	if (queries_num < random_num) random_num = queries_num;
	Statement stmt = conn.createStatement();
	stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + "," + random_num + ")");
	out.println("<script>alert('" + queries_num + " orders are inserted!');</script>");
		}
		else if (action.equals("refresh")) {
	//Need to implement.
		} else if (action.equals("run query")) {
			Statement stmt10 = conn.createStatement();
			Statement stmt11 = conn.createStatement();

			PreparedStatement pstmts = conn
					.prepareStatement("INSERT INTO productColumns (name, total) WITH productInfo(totals, product_id) "
							+ "AS (select sum(orders.price) as totals, product_id FROM orders " + salesCategory
							+ " group by product_id order by totals desc LIMIT 50) SELECT products.name as name, COALESCE(productInfo.totals, 0) as totals "
							+ " FROM products LEFT OUTER JOIN productInfo "
							+ "ON products.id = productInfo.product_id order by totals desc LIMIT 50");
			pstmts.executeUpdate();

			
			PreparedStatement pst2 = conn.prepareStatement("INSERT INTO stateRows (name, total) WITH stateInfo(totals, state_id) AS (select sum(orders.price) as totals, users.state_id as state_id "
					+ " from orders inner join users on orders.user_id = users.id " + salesCategory
					+ " group by users.state_id order by totals desc)"
					+ " SELECT DISTINCT LEFT(states.name,10) as state, coalesce(stateInfo.totals,0) as totals FROM states LEFT OUTER JOIN stateInfo ON states.id = "
					+ "stateInfo.state_id order by totals desc");
			pst2.executeUpdate();

			PreparedStatement pst3 = conn.prepareStatement("INSERT INTO data (product_id, state_id, total) " +
					"with productInfo(product_totals, product_id) as (select sum(orders.price) as totals, product_id from orders group " +
					"by product_id order by totals desc limit 50), " +
					"stateInfo(state_totals, state_id) as (select sum(orders.price) as totals, users.state_id as state_id " +
					"from orders inner join users on orders.user_id = users.id group by users.state_id " +
					"order by totals desc), " +
					"zero(id,product_id,quantity,price,is_cart,user_id,state_id) as " +
					"(select 0,product_id,0,0,false,0,state_id from productInfo,stateInfo), " +
					"orders_stateid(id,product_id,quantity,price,is_cart,user_id,state_id) as " +
					"(select id,product_id,quantity,price,is_cart,u.user_id,u.state_id from orders o inner join (select id as user_id, state_id from users) u on o.user_id = u.user_id " +
					"UNION select * from zero), " +
					"totals as (select coalesce(sum(price),0) as total,state_id,product_id " +
					"from orders_stateid where state_id in (Select state_id from stateInfo) and product_id in (Select product_id from productInfo) " +
					"GROUP BY state_id,product_id), final_table(product_id,state_id,total) as " + 
					"(select t.product_id, t.state_id, total from totals t inner join productInfo pi on t.product_id = pi.product_id " +
					"inner join stateInfo si on t.state_id = si.state_id ORDER BY state_totals desc,product_totals desc) " +
					"select * from final_table;");
			pst3.executeUpdate();
		}
	}
	


	
	
	
	
%>

<body>
	<div class="collapse navbar-collapse">
		<ul class="nav navbar-nav">
			<li><a href="index.jsp">Home</a></li>
			<li><a href="categories.jsp">Categories</a></li>
			<li><a href="products.jsp">Products</a></li>
			<li><a href="orders.jsp">Orders</a></li>
			<li><a href="login.jsp">Logout</a></li>
		</ul>
	</div>
	<div>
		<div>
			<h1>Need to implement! Sales Analytics</h1>
		</div>
		<form action="orders.jsp" method="POST">
			<label># of queries to insert</label> <input type="number"
				name="queries_num"> <input class="btn btn-primary"
				type="submit" name="submit" value="insert" />
		</form>
		<form action="orders.jsp" method="POST">
			<input class="btn btn-success" type="submit" name="submit"
				value="refresh" />
		</form>


		<% 

			String productButton = request.getParameter("ProductButton");
			String stateButton = request.getParameter("StateButton");
			String selectedOrder = request.getParameter("Order");
			String selectedCategory = request.getParameter("Sales");
			String selectedButton = request.getParameter("Button");
			String salesDisplay = "";
			
			if (session.getAttribute("firstTime") == null) {
		session.setAttribute("firstTime", "true");
			}

			//if first time opening page
			if (session.getAttribute("firstTime").equals("true")) {
				session.setAttribute("firstTime", "false");
				if (selectedCategory == null) {
					session.setAttribute("sales", "All");
				}
				session.setAttribute("salesID", "All");
			} else {
				if (selectedCategory == null || selectedOrder == null) {
					selectedCategory = session.getAttribute("salesID").toString();
				} else if (selectedCategory.equals("All")) {
					session.setAttribute("sales", "All");
				} else {
					Statement stmt5 = conn.createStatement();
					ResultSet getName = stmt5
							.executeQuery("select name from categories where id = " + selectedCategory);
					if (getName.next()) {
						session.setAttribute("sales", getName.getString("name"));
						session.setAttribute("salesID", selectedCategory); //id
					}
				}
			}

			if (productButton == null) {
				session.setAttribute("offsetProduct", 0);
			}
			if ("Products".equals(productButton)) {
				int num = (Integer) session.getAttribute("offsetProduct") + 10;
				session.setAttribute("offsetProduct", num);
				System.out.println("order in product button = " + session.getAttribute("order"));
				//System.out.println("offset product = " + session.getAttribute("offsetProduct"));
			}

			if (stateButton == null) {
				session.setAttribute("offsetState", 0);
			}
			if ("States".equals(stateButton)) {
				int num = (Integer) session.getAttribute("offsetState") + 20;
				session.setAttribute("offsetState", num);
				//System.out.println("offset state = " + session.getAttribute("offsetState"));
			}

			if ("Alphabetical".equals(selectedOrder)) {
				//System.out.println("selected cateogyr  asdjfad = " + selectedCategory);
				productOrder = orderName;
				stateOrder = orderState;
				if (!"All".equals(selectedCategory)) {
					salesCategory = "inner join products on orders.product_id = products.id where products.category_id = "
							+ selectedCategory;
					salesCategoryMenu = "where id = " + selectedCategory;
					salesDisplay = "and products.category_id = " + selectedCategory;
					session.setAttribute("salesID", selectedCategory);
					//come back
				}
				session.setAttribute("order", "Alphabetical");
			}
			if ("Top-K".equals(selectedOrder)) {
				productOrder = orderTopK;
				stateOrder = orderTopK;
				if (!"All".equals(selectedCategory)) {
					salesCategory = "inner join products on orders.product_id = products.id where products.category_id = "
							+ selectedCategory;
					salesCategoryMenu = "where id = " + selectedCategory;
					salesDisplay = "and products.category_id = " + selectedCategory;
				} else {
					salesCategoryMenu = "";
				}
				session.setAttribute("order", "Top-K");
			}
		

		Statement stmt = conn.createStatement();
		Statement stmt2 = conn.createStatement();
		Statement stmt3 = conn.createStatement();
		Statement stmt4 = conn.createStatement();
		Statement stmt6 = conn.createStatement();
		Statement stmt7 = conn.createStatement();

		ResultSet rsSum = null;
		ResultSet rsProducts = null;
		ResultSet rsCategories = stmt6.executeQuery("SELECT name, id FROM categories");
		int product_id;
		ResultSet rsCatSize = stmt7
				.executeQuery("select count(*) as size from (select state_id from users group by state_id) a");
		if (rsCatSize.next()) {
			session.setAttribute("stateNum", rsCatSize.getInt("size"));
		}
		ResultSet rsProductSize = stmt4
				.executeQuery("select count(*) as size from (select name from products group by name) a");
		if (rsProductSize.next()) {
			session.setAttribute("productNum", rsProductSize.getInt("size"));
		}
		//System.out.println("product size = " + session.getAttribute("productNum"));
	%>


		<div class="collapse navbar-collapse">
			<ul class="nav navbar-nav">
				<li><a href="index.jsp">Home</a></li>
				<li><a href="categories.jsp">Categories</a></li>
				<li><a href="products.jsp">Products</a></li>
				<li><a href="orders.jsp">Orders</a></li>
				<li><a href="login.jsp">Logout</a></li>
			</ul>
		</div>
		<div>
			<div>
				<h1>Sales Analytics</h1>
			</div>

			<div class="form-group">
				<form action="StateOrders.jsp" method="POST">
					</select> <label for="Sales">Sales-Filtering:</label> <select name="Sales"
						id="sales" class="form-control">
						<option value=<%=session.getAttribute("sales")%>><%=session.getAttribute("sales")%></option>
						<option value="All">All</option>
						<%
							while (rsCategories.next()) {
								String category = rsCategories.getString("name");
								String category_id = rsCategories.getString("id");
						%>
						<option value=<%=category_id%>
							<%if (category.equals(session.getAttribute("sales"))) {%>
							selected="selected" <%}%>><%=category%></option>

						<%
							}
						%>
					</select>
					<td><input class="btn btn-primary" type="submit" name="submit"
						value="Run Query" /></td>
				</form>
			</div>


			<table class="table table-striped">
				<th></th>
				<%

				
					rsProducts = stmt2.executeQuery("select * from productColumns");

					while (rsProducts.next()) { //dispaly products
				%>
				<th><%=rsProducts.getString("name")%> (<%=rsProducts.getFloat("total")%>)</th>
				<%
					}

					ResultSet rsState = stmt.executeQuery("select * from stateRows");
				%>

				<tbody>
					<%
					int count = 0;
					ResultSet rs2 = stmt3.executeQuery("select * from data");
						while (rsState.next()) { //loop through states												
					%>
					<tr>
						<th><%=rsState.getString("name")%> (<%=rsState.getFloat("total")%>)</th>
						<%
						
						while (count < 50 && rs2.next()) { //loop through to get products sum
							count++; 					%>
							<td><%=rs2.getFloat("total")%></td>
							<% 
							} 
							count = 0; %>
							
					<% } %>

		
		</tr>
		</tbody>
		</table>
	
					
					
</body>
</html>



















