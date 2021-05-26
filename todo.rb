require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do 
  session[:lists] ||= []
end

get "/" do
 redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb(:lists, layout: :layout)
end


# Render the new list form
get "/lists/new" do 
  erb(:new_list, layout: :layout)
end

# Render a list with ability ta add todo item
get "/lists/:id" do 
  # get the todos from this particular list
  # send to view template
 @list_id = params[:id].to_i
 @lists = session[:lists]
 @list = session[:lists][@list_id]
 erb(:list, layout: :layout)
end


# Edit an existing todo list
get "/lists/:id/edit" do 
  @id = params[:id].to_i
  @list = session[:lists][@id]
  
  erb(:edit_list, layout: :layout)
end

helpers do 
  def list_complete?(list)
    has_a_todo = todos_count(list) > 0
    all_complete = todos_remaining_count(list) == 0
    has_a_todo && all_complete
  end

  def list_class(list)
   "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].count {|todo| !todo[:completed]}
  end

  def sort_lists(lists, &block)
    incomplete_lists = {}
    complete_lists = {}

    lists.each_with_index do |list, index|
      if list_complete?(list)
        complete_lists[index] = list
      else
        incomplete_lists[index] = list
      end
    end
    
    incomplete_lists.each {|id, list| yield(list, id)}
    complete_lists.each {|id, list| yield(list, id)}
  end
end 

def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    return  "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    return  "List name must be unique."
  end
end 

# Create a new list
post "/lists" do 
  # remove unnecessary white-space
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb(:new_list, layout: :layout)
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end 
end

# Udpate an exisiting todo list name
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]
  
  error = error_for_list_name(list_name)
  if error
    @list = session[:lists][@id]
    session[:error] = error
    erb(:edit_list, layout: :layout)
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@id}"
  end
end

# Delete a list from session
post "/lists/:id/delete" do 
  id = params[:id].to_i
  session[:lists].delete_at(id)
  
  session[:success] = "The list has been deleted."
  
  redirect "/lists"
end

def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters."
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do 
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb(:list, layout: :layout)
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo item from a list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# Update the status of a todo: complete or undo complete
post "/lists/:list_id/todos/:id" do 
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

def complete_all(todos)
  todos.each do |todo|
    todo[:completed] = true
  end
end
# Mark all todos as complete
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  p @list = session[:lists][@list_id]
  
  p @todos = @list[:todos]
  complete_all(@todos)
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end