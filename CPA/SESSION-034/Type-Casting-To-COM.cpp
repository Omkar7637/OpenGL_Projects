pIunknown->QueryInterface(IID_A, reinterpret_cast<void**>&pIA)


class C
{
    public: 
        HRESULT STDCALL QueryInterface(iid_t iid, void** ppInterface)
        {
            if(iid == IID_A)
            {
                *(reinterpret_cast<IA**>ppInterface) = static_cast<IA*>(this); 
                *(reinterpret_cast<IA**>ppInterface)->AddRef(); 
            }
            else if(iid == IID_B)
            {
                 *(reinterpret_cast<IB**>ppInterface) = static_cast<IB*>(this); 
            } 
            else if(iid == IID_C)
            {
                 *(reinterpret_cast<IC**>ppInterface) = static_cast<IC*>(this); 
            } 
            else 
            {
                *ppInterface = NULL; 
                return (S_FAILED); 
            }
            
            (*reinterpret_cast<IUnknown**>(this))->AddRef(); 
            return S_OK; 

        }
}