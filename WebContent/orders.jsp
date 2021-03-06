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
	<script type="text/javascript" src="orderFunctions.js"></script>
</head>



<%
Connection conn = null;
String orderName = " ORDER BY name ";
String orderState = " ORDER BY state ";
String orderTopK = " ORDER BY totals desc";
String productOrder = orderName;
String stateOrder = orderState;
String salesCategory = "";

	try {
		Class.forName("org.postgresql.Driver");
	    String url = "jdbc:postgresql://localhost:5433/cse135pt3";
	    String admin = "postgres";
	    String password = "alin";
  	conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	
	
	String selectedCategory = request.getParameter("Sales");
	
	if (session.getAttribute("firstTime") == null) {
		session.setAttribute("firstTime", "true");
	}

	//if first time opening page
	if (session.getAttribute("firstTime").equals("true")) {
		if (selectedCategory == null) {
			session.setAttribute("sales", "All");
		}
		session.setAttribute("salesID", "All");
	} else {
		if ("All".equals(selectedCategory)) {
			session.setAttribute("sales", "All");
			salesCategory = " ";
		
		} else {
			Statement stmt5 = conn.createStatement();
			ResultSet getName = stmt5
					.executeQuery("select name from categories where id = " + selectedCategory);
			if (getName.next()) {
				session.setAttribute("sales", getName.getString("name"));
				session.setAttribute("salesID", selectedCategory); //id
				salesCategory = "inner join products on orders.product_id = products.id where products.category_id = "
						+ selectedCategory;

			}
		}
	}

	if (session.getAttribute("firstTime").equals("true")) {
		session.setAttribute("firstTime", "false");
		Statement stmt10 = conn.createStatement();
		Statement stmt11 = conn.createStatement();

		//create temporary tables
		PreparedStatement pstmts = conn.prepareStatement("CREATE TEMP TABLE productColumns( "
				+ " id SERIAL PRIMARY KEY, name TEXT NOT NULL, total FLOAT NOT NULL CHECK (total >= 0)); "
				+ "CREATE TEMP TABLE stateRows(id SERIAL PRIMARY KEY,name TEXT NOT NULL UNIQUE,total FLOAT NOT NULL CHECK (total >= 0)); "
				+ "CREATE TEMP TABLE data(product_id INTEGER NOT NULL,state_id INTEGER NOT NULL,total FLOAT NOT NULL CHECK (total >= 0));"
				+ "CREATE INDEX p_id ON data(product_id); CREATE INDEX S_ID ON data(state_id);");
		pstmts.executeUpdate();

		PreparedStatement pstmts2 = conn.prepareStatement(
				"INSERT INTO productColumns (id, name, total) WITH productInfo(totals, product_id) "
						+ "AS (select sum(orders.price) as totals, product_id FROM orders "
						+ " group by product_id order by totals desc LIMIT 50) SELECT products.id as id, products.name as name, COALESCE(productInfo.totals, 0) as totals "
						+ " FROM products LEFT OUTER JOIN productInfo "
						+ "ON products.id = productInfo.product_id order by totals desc LIMIT 50");
		pstmts2.executeUpdate();

		PreparedStatement pst2 = conn.prepareStatement(
				"INSERT INTO stateRows (name, total, id) WITH stateInfo(totals, state_id) AS (select sum(orders.price) as totals, users.state_id as state_id "
						+ " from orders inner join users on orders.user_id = users.id "
						+ " group by users.state_id order by totals desc)"
						+ " SELECT DISTINCT LEFT(states.name,10) as state, coalesce(stateInfo.totals,0) as totals, states.id as id FROM states LEFT OUTER JOIN stateInfo ON states.id = "
						+ "stateInfo.state_id order by totals desc");
		pst2.executeUpdate();

		PreparedStatement pst3 = conn.prepareStatement("INSERT INTO data (product_id, state_id, total) "
				+ "with zero(id,product_id,quantity,price,is_cart,user_id,state_id) as "
				+ "(select 0,productColumns.id,0,0,false,0,stateRows.id from productColumns,stateRows), "
				+ "orders_stateid(id,product_id,quantity,price,is_cart,user_id,state_id) as "
				+ "(select id,product_id,quantity,price,is_cart,u.user_id,u.state_id from orders o inner join (select id as user_id, state_id from users) u on o.user_id = u.user_id "
				+ "UNION select * from zero), "
				+ "totals as (select coalesce(sum(price),0) as total,state_id,product_id "
				+ "from orders_stateid where state_id in (Select id from stateRows) and product_id in (Select id from productColumns) "
				+ "GROUP BY state_id,product_id), final_table(product_id,state_id,total) as "
				+ "(select t.product_id, t.state_id, t.total from totals t inner join productColumns pi on t.product_id = pi.id "
				+ "inner join stateRows si on t.state_id = si.id ORDER BY si.total desc,pi.total desc) "
				+ "select * from final_table;");
		pst3.executeUpdate();
		
		//find the most recent log id
		PreparedStatement pst4 = conn.prepareStatement("SELECT MAX(id) as id FROM log");
		ResultSet rs4 = pst4.executeQuery();
		if( rs4.next() ){
			session.setAttribute("last_log_id", rs4.getInt("id"));
			System.out.println("last id set as " + rs4.getInt("id"));
		%> 
			<div>
			   <input type="hidden" id="lastlogid" name="lastlogid" form="insertform" value="<%=rs4.getInt("id")%>"> 
			</div>		
			
		  <%
		}
	}

	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String action = request.getParameter("submit");
		if (action.equals("insert")) {
			String lastlogid = request.getParameter("lastlogid");
			%><input type="hidden" id="lastlogid" name="lastlogid" form="insertform" value="<%=lastlogid%>"> <%
			int queries_num = Integer.parseInt(request.getParameter("queries_num"));
			Random rand = new Random();
			int random_num = rand.nextInt(30) + 1;
			if (queries_num < random_num)
				random_num = queries_num;
			Statement stmt = conn.createStatement();
			Statement stmtLog = conn.createStatement();
			PreparedStatement pst = conn
					.prepareStatement("INSERT INTO log (startID, endID) select max(id)+1, max(id) + "
							+ queries_num + " from orders");
			pst.executeUpdate();
			stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + "," + random_num + ")");
			out.println("<script>alert('" + queries_num + " orders are inserted!');</script>");

		} else if (action.equals("refresh")) {
			//Need to implement.
		} else if (action.equals("RunQuery")) {

			Statement stmt10 = conn.createStatement();
			Statement stmt11 = conn.createStatement();

			PreparedStatement pstmts = conn
					.prepareStatement(" DELETE FROM data; DELETE FROM productColumns; DELETE FROM stateRows;");
			pstmts.executeUpdate();

			PreparedStatement pstmts2 = conn.prepareStatement(
					"INSERT INTO productColumns (id, name, total) WITH productInfo(totals, product_id) "
							+ "AS (select sum(orders.price) as totals, product_id FROM orders " + salesCategory
							+ " group by product_id order by totals desc LIMIT 50) SELECT products.id as id, products.name as name, COALESCE(productInfo.totals, 0) as totals "
							+ " FROM products LEFT OUTER JOIN productInfo "
							+ "ON products.id = productInfo.product_id order by totals desc LIMIT 50");
			pstmts2.executeUpdate();

			PreparedStatement pst2 = conn.prepareStatement(
					"INSERT INTO stateRows (name, total, id) WITH stateInfo(totals, state_id) AS (select sum(orders.price) as totals, users.state_id as state_id "
							+ " from orders inner join users on orders.user_id = users.id " + salesCategory
							+ " group by users.state_id order by totals desc)"
							+ " SELECT DISTINCT LEFT(states.name,10) as state, coalesce(stateInfo.totals,0) as totals, states.id as id FROM states LEFT OUTER JOIN stateInfo ON states.id = "
							+ "stateInfo.state_id order by totals desc");
			pst2.executeUpdate();


			PreparedStatement pst3 = conn.prepareStatement("INSERT INTO data (product_id, state_id, total) "
					+ "with zero(id,product_id,quantity,price,is_cart,user_id,state_id) as "
					+ "(select 0,productColumns.id,0,0,false,0,stateRows.id from productColumns,stateRows), "
					+ "orders_stateid(id,product_id,quantity,price,is_cart,user_id,state_id) as "
					+ "(select id,product_id,quantity,price,is_cart,u.user_id,u.state_id from orders o inner join (select id as user_id, state_id from users) u on o.user_id = u.user_id "
					+ "UNION select * from zero), "
					+ "totals as (select coalesce(sum(price),0) as total,state_id,product_id "
					+ "from orders_stateid where state_id in (Select id from stateRows) and product_id in (Select id from productColumns) "
					+ "GROUP BY state_id,product_id), final_table(product_id,state_id,total) as "
					+ "(select t.product_id, t.state_id, t.total from totals t inner join productColumns pi on t.product_id = pi.id "
					+ "inner join stateRows si on t.state_id = si.id ORDER BY si.total desc,pi.total desc) "
					+ "select * from final_table;");
			pst3.executeUpdate();
			
			//find the most recent log id
			PreparedStatement pst4 = conn.prepareStatement("SELECT MAX(id) as id FROM log");
			ResultSet rs4 = pst4.executeQuery();
			if( rs4.next() ){
				session.setAttribute("last_log_id", rs4.getInt("id"));
				System.out.println("last id set as " + rs4.getInt("id"));
				%> 
				<div>
				   <input type="hidden" id="lastlogid" name="lastlogid" form="insertform" value="<%=rs4.getInt("id")%>"> 
				</div>		
				
			  <%
			}
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
		<form action="orders.jsp" method="POST" id="insertform">
			
			<label># of queries to insert</label> <input type="number"
				name="queries_num"> <input class="btn btn-primary"
				type="submit" name="submit" value="insert" />
		</form>



		<% 

			
		Statement stmt = conn.createStatement();
		Statement stmt2 = conn.createStatement();
		Statement stmt3 = conn.createStatement();
		Statement stmt4 = conn.createStatement();
		Statement stmt6 = conn.createStatement();
		Statement stmt7 = conn.createStatement();

		ResultSet rsSum = null;
		ResultSet rsProducts = null;
		ResultSet rsCategories = stmt6.executeQuery("SELECT name, id FROM categories");

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
				<form action="orders.jsp" method="POST">
					</select> <label for="Sales">Sales-Filtering:</label> <select name="Sales"
						id="sales" class="form-control">
						<option value=<%=session.getAttribute("sales")%>><%=session.getAttribute("sales")%></option>
						<option value="All">All</option>
						<%
							System.out.println("current log id is: " + session.getAttribute("last_log_id"));
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
						value="RunQuery" /></td>
				</form>
			</div>

<div>
<p id="missingproducts"></p>
</div>

			<table id="mytable" class="table table-striped">
				<th></th>
				<%

				
					rsProducts = stmt2.executeQuery("select * from productColumns");
					
					ArrayList<String> productList =  new ArrayList<String>();
					String pString = "";
					while (rsProducts.next()) { //display products
				%>
				<th id="P<%=Integer.toString(rsProducts.getInt("id"))%>"><%=rsProducts.getString("name")%> (<%=rsProducts.getFloat("total")%>)</th>
				<%
						pString += Integer.toString(rsProducts.getInt("id")) + ":";
						productList.add(Integer.toString(rsProducts.getInt("id")));
					}
					pString = pString.substring(0,pString.length() - 1);	
					
					ResultSet rsState = stmt.executeQuery("select * from stateRows");
				%>

				<tbody>
					<%
					int count = 0;
					ResultSet rs2 = stmt3.executeQuery("select * from data");
						while (rsState.next()) { //loop through states	
							//System.out.println(Integer.toString(rsState.getInt("id")));
					%>
					<tr>
						<th id="S<%=Integer.toString(rsState.getInt("id"))%>"><%=rsState.getString("name")%> (<%=rsState.getFloat("total")%>)</th>
						<%
						
						while (count < 50 && rs2.next()) { //loop through to get products sum
							count++; 					%>
							<td id="<%=productList.get(count-1) + "_" + Integer.toString(rsState.getInt("id"))%>"><%=rs2.getFloat("total")%></td>
							<% 
							} 
							count = 0; %>
							
					<% } %>

		
		</tr>
		</tbody>
		</table>
	
			<div>
			   <input type="hidden" name="testid" id="testid" value="5" />
			</div>
			<form action="orders.jsp" method="POST">
			<input class="btn btn-success" type="button" name="submit"
				value="refresh" onClick="refresh('plist=<%= pString%>');" style="position: fixed; bottom: 0px; right: 0px"/>
			</form>		
</body>
</html>



















