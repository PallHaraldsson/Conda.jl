module Conda
using Compat

const PREFIX = Pkg.dir("Conda", "deps", "usr")
const conda = joinpath(PREFIX, "bin", "conda")
const DL_LOAD_PATH = VERSION >= v"0.4.0-dev+3844" ? Libdl.DL_LOAD_PATH : Base.DL_LOAD_PATH

CHANNELS = AbstractString[""]
additional_channels() = join(CHANNELS, " -c ")

function __init__()
    # Let's see if Conda is installed. If not, let's do that first!
    install_conda()
    # Update environment variables such as PATH, DL_LOAD_PATH, etc...
    update_env()
end

# Get the miniconda installer URL.
function installer_url()
    res = "https://repo.continuum.io/miniconda/Miniconda-latest-"
    if OS_NAME == :Darwin
        res *= "MacOSX"
    elseif OS_NAME in [:Linux, :Windows]
        res *= string(OS_NAME)
    else
        error("Unsuported OS.")
    end

    if WORD_SIZE == 64
        res *= "-x86_64"
    else
        res *= "-x86"
    end

    if OS_NAME in [:Darwin, :Linux]
        res *= ".sh"
    else
        res *= ".exe"
    end
    return res
end


function install_conda()
    # Ensure PREFIX exists
    mkpath(PREFIX)

    # Make sure conda isn't already installed
    if !isexecutable(conda)
        info("Downloading miniconda installer …")
        installer = joinpath(PREFIX, "installer")
        download(installer_url(), installer)
        chmod(installer, 33261)  # 33261 corresponds to 755 mode of the 'chmod' program
        run(`$installer -b -f -p $PREFIX`)
    end
end

# Update environment variables so we can natively call conda, etc...
function update_env()
    if length(Base.search(ENV["PATH"], joinpath(PREFIX, "bin"))) == 0
        ENV["PATH"] = "$(realpath(joinpath(PREFIX, "bin"))):$(ENV["PATH"])"
    end
    if !(joinpath(PREFIX, "lib") in DL_LOAD_PATH)
        push!(DL_LOAD_PATH, joinpath(PREFIX, "lib") )
    end
end

function add(pkg::AbstractString)
    channels = additional_channels()
    run(`$conda install -y $(split(channels)) $pkg`)
end

function rm(pkg::AbstractString)
    run(`$conda remove -y $pkg`)
end

function update()
    channels = additional_channels()
    run(`$conda install -y conda`)
    run(`$conda update $(split(channels)) -y`)
end

function list()
    run(`$conda list`)
end

function exists(package::AbstractString)
    channels = additional_channels()
    res = readall(`$conda search $(split(channels)) --full-name $package`)
    if chomp(res) == "Fetching package metadata: ...."
        # No package found
        return false
    else
        return true
    end
end

include("bindeps.jl")

end
