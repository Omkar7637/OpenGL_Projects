int max_int(int const& n1, int const& n2)
{

}

float max_float(float const& n1, float const& n2)
{

}

std::string max_string(std::string const& s1, std::string const& s2)
{

}
#-----------------------------------------------------------------------

template <typename T> 
T cpa_max(T const& n1, T const& n2)
{
    if(n1 > n2)
        return n1; 
    return n2; 
}

test()
{
    cpa_max<int>(m, n); 
    push n 
    push m 
    call mangled_version_of_cpa_max_for_int
    cpa_max<float>(f_num1, f_num2); 
    cpa_max<std::string(s1, s2); 
}

int cpa_max(int const& n1, int const& n2)
{
    if(n1 > n2)
        return n1; 
    return n2; 
}

float cpa_max(float const& n1, float const& n2)
{
    if(n1 > n2)
        return n1; 
    return n2; 
}

std::string cpa_max(std::string const& n1, std::string const& n2)
{
    if(n1 > n2)
        return n1; 
    return n2; 
}