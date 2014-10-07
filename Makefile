bench:
	ruby generate_csv.rb

website:
	ruby generate_html.rb

server:
	ruby -run -e httpd html/ -p 8080
