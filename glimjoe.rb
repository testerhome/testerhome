#Ruby 之 HelloWorld

#版本1
def say_hello1(name)
  return "Hello , "+ name  
end

#版本2
def say_hello2 name
  return "Hello , " + name
end

#版本3
def say_hello3 name
  return "Hello , #{name}"
end

puts say_hello1 "lql1"
puts say_hello2 "lql2"
puts say_hello3 "lql3"