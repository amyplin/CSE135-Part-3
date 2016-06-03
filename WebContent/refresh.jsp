<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.util.*, org.json.simple.*"%>



<%-- find the last log that was looked at --%>
<%
	// retrieves the latest log id
	int last_log_id = Integer.parseInt(request.getParameter("last_log_id"));

	System.out.println("last log id is " + last_log_id);

	// make connections to the database
	Connection conn = null;
	try{
		Class.forName("org.postgresql.Driver");
	    String url = "jdbc:postgresql://localhost:5433/cse135pt3";
	    String admin = "postgres";
	    String password = "alin";
  		conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	
	//product list
	String plist = request.getParameter("plist");
	String[] splitted =plist.split(":");
	
	ArrayList<String> productList = new ArrayList<String>(Arrays.asList(splitted));
	ArrayList<String> tempList = new ArrayList<String>(Arrays.asList(splitted));
	

	
	
	Statement stmt_products = conn.createStatement();
	ResultSet rs_products = stmt_products.executeQuery("SELECT sum(price) as total, product_id FROM orders GROUP BY product_id ORDER BY total DESC LIMIT 50");
	ArrayList<String> newProductList = new ArrayList<String>();
	while (rs_products.next()) {
		newProductList.add(Integer.toString(rs_products.getInt("product_id")));
	}
	
	productList.removeAll(newProductList); //purple elements are in productList
	newProductList.removeAll(tempList); //items that have to be added
	
	
	
	for (String prod : productList) {
		
	}
	
	// finds the newest order id from the log, if any
	PreparedStatement pstmt = conn.prepareStatement("select startID from log where log.id > ? LIMIT 1;");
	pstmt.setInt(1, last_log_id);
	ResultSet rs = pstmt.executeQuery();
	
	// retrive the newest orderid
	JSONArray result = new JSONArray();
	
	//add purple and to-be-added products to the json result
	JSONArray purplearray = new JSONArray();
	for(int i = 0; i < productList.size(); i++){
		purplearray.add(productList.get(i));
	}
	result.add(purplearray);
	
	JSONArray missingproducts = new JSONArray();
	for(int i = 0; i < newProductList.size(); i++){
		missingproducts.add(newProductList.get(i));
	}
	result.add(missingproducts);
	
	
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
			//System.out.println("stateid = " + state_id + " productid = " + product_id);
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