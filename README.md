# Toolkits.jl
## Data maipulate
`@pip` and `@pipas` enable R's `%>%` and `%<>%` syntax. Arguments are seperated by space. Broadcasting and anonymous functions are supported; however, `@pipas` can only assign global variable.
## Package management
`@activite` enables `Pkg.activity` functionality. Environment name doesn't have to be quoted, and the shared argument is set true. This a convenient way to access existed environment in [./.julia/environments](./.julia/environments).
