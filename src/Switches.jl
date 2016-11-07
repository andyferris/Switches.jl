module Switches

export Switch, Unknown, Optional

import Base: @pure, broadcast, promote_op

include("Switch.jl")
include("Optional.jl")

end # module
