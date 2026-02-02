#ifndef _MAX_HPP 
#define _MAX_HPP 

template <typename T> 
T cpa_max(T const& n1, T const& n2)
{
    if(n1 > n2)
        return n1; 
    return n2; 
}

#endif /* _MAX_HPP */
