function refresh(pString){
var lastlogid = document.getElementById("lastlogid").value;
alert(lastlogid);
	
$.ajax({
	  	type: 'POST',
	  	url: "refresh.jsp?" + "last_log_id=" + lastlogid + "&" + pString,
	  	success:function(result){
	  		
  		var response = $.parseJSON(result);	
	  		
	  	if(!response[2]){
	  		alert("no new data");
		 	//Set table cells to black
		  	var table = document.getElementById("mytable");

		  	for (var i = 0, row; row = table.rows[i]; i++) {
		
		        for (var j = 0, cell; cell = row.cells[j]; j++) {
		        	cell.style.color = "black";
		        	cell.style.backgroundColor = "white";
		        }
		    }
	  	} else {
	  		
	 	//Set table cells to black
	  	var table = document.getElementById("mytable");

	  	for (var i = 0, row; row = table.rows[i]; i++) {
	
	        for (var j = 0, cell; cell = row.cells[j]; j++) {
	        	cell.style.color = "black";
	        	cell.style.backgroundColor = "white";
	        }
	    }
	  	
	  	
	  	
	  	var logmax = response[2].max_order_id;//the new max log id
	  	document.getElementById("lastlogid").value = logmax;
	  	
	  	var purplelist = response[0];
	  	var missinglist = response[1];

	  	
	  	// change background to purple for all purple IDs
	  	for( var x = 0; x < purplelist.length; x++){
	  		var id = purplelist[x];
	  		//change the header
	  		document.getElementById("P" + id).style.backgroundColor = "plum";
	  		
	  		//change all the columns
	  		var cellnumber = document.getElementById("P" + id).cellIndex;
	  		for( var y = 1; y < 51; y++){
	  			document.getElementById("mytable").rows[y].cells[cellnumber].style.backgroundColor = "plum";
	  		}
	  		
	  	}
	  	
	  	//display a list of items to be inserted
//	  	for( var x = 0; x < missinglist.length; x++){
//	  		var text = document.getElementById("missingproducts").innerHTML;
//	  		document.getElementById("missingproducts").innerHTML = text + "|" + missinglist[x];
//	  	}
//	  	
//	  	var text = document.getElementById("missingproducts").innerHTML;
  		document.getElementById("missingproducts").innerHTML = missinglist;
	  	
	  	
	  	for (var r =2, block; block = response[r]; r++) {
	  		
	  		
	  		var si = block.state_id;
	  		var pi = block.product_id;
	  		var price = block.price;
	  		
	  		
	  		//state_product
	  		if (document.getElementById("S" + si.toString()) && document.getElementById("P" + pi.toString())) {
		  		document.getElementById(pi.toString() + "_" + si.toString()).style.color = "red";
		  		var currVal = document.getElementById(pi.toString() + "_" + si.toString()).innerHTML;
		  		var currPrice = (Number(parseFloat(currVal.replace(/[^0-9.]/g,'')) + price).toFixed(2)).toString();
		  		document.getElementById(pi.toString() + "_" + si.toString()).innerHTML = currPrice;

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
	  	}
	  	
	  	},
	  	error:function(){
			// Failed request
			alert("JSP failed");
	  	}
	});
	
}