<?php
// {{ ansible_managed }}

$APP = "Web Launcher";
$VIEWER_HOST = "{{ viewer_hostname }}";
$DOWNLOAD_LINK = "{{ apk_url }}";
$VIEWER_VNC_WIDTH = 825;
$VIEWER_VNC_HEIGHT = 635;

// list links below, one per line; format is "display text" => "http://thelink.com",
$links = array(
	{% for item in links %}
	"{{ item.title }}" => "{{ item.link }}",	
	{% endfor %}
);
?>
