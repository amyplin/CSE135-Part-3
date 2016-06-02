<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.util.*, org.json.simple.*"%>

<%-- find the last log that was looked at --%>
<%
	// retrieves the latest log id
	int last_log_id = Integer.parseInt(request.getParameter("last_log_id"));

	// make connections to the database
	Connection conn = null;
	try{
		Class.forName("org.postgresql.Driver");
		String url = "jdbc:postgresql://localhost:5432/postgres";
	    String admin = "postgres";
	    String password = "password";
  		conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	
	// finds the newest order id from the log, if any
	PreparedStatement pstmt = conn.prepareStatement("select startID from log where log.id > ? LIMIT 1;");
	pstmt.setInt(1, last_log_id);
	ResultSet rs = pstmt.executeQuery();
	
	// retrive the newest orderid
	JSONArray result = new JSONArray();
	if( rs.next() )
	{
		int last_order_id = rs.getInt("startID");
		PreparedStatement pstmt2 = conn.prepareStatement("with mytable as(" + 
				"select max(id) as id from log)" + 
				"select (select state_id from users where id = user_id) as state_id , product_id, price, (select id from mytable) from orders where id > ?");
		pstmt2.setInt(1, last_order_id);
		ResultSet rs2 = pstmt2.executeQuery();
		
		
		// add new orders to the JSON object
		while(rs2.next())
		{
			//last log id
			int max_order_id = rs2.getInt("id");
			//state id
			int state_id = rs2.getInt("state_id");
			//product id
			int product_id = rs2.getInt("product_id");
			//price
			int price = rs2.getInt("price");
			
			JSONObject resultobject = new JSONObject();

			
			resultobject.put("max_order_id",max_order_id);
			resultobject.put("state_id",state_id);
			resultobject.put("product_id",product_id);
			resultobject.put("price",price);

			result.add(resultobject);
		}
		
	} else {

	}
	
	// return the result JSON Object
	out.print(result);
	out.flush();
	
%>