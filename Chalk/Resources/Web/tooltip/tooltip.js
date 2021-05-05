var tooltip = function() {
	var id = 'tt';
	var speed = 10;
	var showHideDuration = 20;
	var endalpha = 95;
	var alpha = 0;
	var tt;
	return {
		show:function(v){
			if(tt == null){
				tt = document.createElement('div');
				tt.setAttribute('id',id);
				tt.style.color = 'white';
				tt.style.position = 'absolute';
				tt.style.borderRadius = '5px';
				tt.style.background = 'rgb(64, 64, 64)';
				tt.style.padding = '1px 4px 1px 4px';
				tt.style.fontSize = 'smaller';
				document.body.appendChild(tt);
				document.onmousemove = this.pos;
			}
			tt.style.display = 'block';
			tt.innerHTML = v;
			tt.style.width = 'auto';
			clearInterval(tt.timer);
			tt.timer = setInterval(function(){tooltip.fade(1)}, showHideDuration);
		},
		pos:function(e){
			var u = e.pageY;
			var l = e.pageX;
			var h = parseInt(tt.offsetHeight);
			tt.style.top = (u - h) - 10 + 'px';
			tt.style.left = (l + 0) + 'px';
		},
		fade:function(d){
			var a = alpha;
			if((a != endalpha && d == 1) || (a != 0 && d == -1)){
				var i = speed;
				if(endalpha - a < speed && d == 1){
					i = endalpha - a;
				}else if(alpha < speed && d == -1){
					i = a;
				}
				alpha = a + (i * d);
				tt.style.opacity = alpha * .01;
				tt.style.filter = 'alpha(opacity=' + alpha + ')';
			}else{
				clearInterval(tt.timer);
				if(d == -1){tt.style.display = 'none'}
			}
		},
		hide:function(){
			clearInterval(tt.timer);
			tt.timer = setInterval(function(){tooltip.fade(-1)}, showHideDuration);
		}
	};
}();