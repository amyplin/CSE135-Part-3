function refresh(logid){
	
$.ajax({
	  	type: 'POST',
	  	url: "refresh.jsp?" + logid,
	  	success:function(result){
		  		
	 	//Set table cells to black
	  	var table = document.getElementById("mytable");

	  	for (var i = 0, row; row = table.rows[i]; i++) {
	
	        for (var j = 0, cell; cell = row.cells[j]; j++) {
	        	cell.style.color = "black";
	        }
	    }
	  	
	  	var response = $.parseJSON(result);	
	  	
	  	var logmax = response[0].max_order_id;
	  	for (var r =0, block; block = response[r]; r++) {
	  		
	  		var si = block.state_id;
	  		var pi = block.product_id;
	  		var price = block.price;
	  		
	  		
	  		//state_product
	  		if (document.getElementById("S" + si.toString()) && document.getElementById("P" + pi.toString())) {
		  		document.getElementById(si.toString() + "_" + pi.toString()).style.color = "red";
		  		var currVal = document.getElementById(si.toString() + "_" + pi.toString()).innerHTML;
		  		var currPrice = (parseFloat(currVal.replace(/[^0-9.]/g,'')) + price).toString();
		  		document.getElementById(parseInt(si) + "_" + parseInt(pi)).innerHTML = currPrice;
	  		
	  		}
	  			
	  		//state
	  		if (document.getElementById("S" + si.toString())) {
	  			document.getElementById("S" + si.toString()).style.color = "red";
	  			var scurrVal = document.getElementById("S" + si.toString()).innerHTML;
	  			var state = scurrVal.substr(0, scurrVal.indexOf('('));
	  			var currPrice = (parseFloat(scurrVal.replace(/[^0-9.]/g,'')) + price).toString();
		  		document.getElementById("S" + si.toString()).innerHTML = state + "(" + currPrice + ")";
	  		}
	  		
	  		//product
	  		if (document.getElementById("P" + pi.toString())) {
	  			document.getElementById("P" + pi.toString()).style.color = "red";
	  			var pcurrVal = document.getElementById("P" + pi.toString()).innerHTML;
	  			var product = pcurrVal.substr(0, pcurrVal.indexOf('('));
	  			var currPrice = (parseFloat(pcurrVal.replace(/[^0-9.]/g,'')) + price).toString();
		  		document.getElementById("P" + pi.toString()).innerHTML = product + "(" + currPrice + ")";
	  		}
	  	}

	  	alert("refreshed");
	  	},
	  	error:function(){
			// Failed request
			alert("JSP failed");
	  	}
	});
	
}