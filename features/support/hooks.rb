# Before each scenario
Before do
end

# After each scenario
After do
  ## This is a workaround for https://github.com/jnicklas/capybara/issues/1001
  ## Solution found on https://groups.google.com/d/msg/selenium-users/qahuzVl1svQ/hR6FO3GGzDMJ
  page.execute_script("window.localStorage.clear()")##This works for FF
end


# Step hooks

# After each step
AfterStep do |step|
  jserror = find("body")["JSError"]
  jserror.should(eq(nil), "JavaScript error: #{jserror}")
end