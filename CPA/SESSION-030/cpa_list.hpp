namespace cpa 
{
    namespace dsa 
    {
        template <typename T> 
        class node 
        {
            template <typename T> 
            friend class list<T>; 
            private: 
                T const& data; 
                node* prev; 
                node* next; 
                node(T const& _data) : data(_data)
                {

                }
        }; 

        template <typename T> 
        class list 
        {
            private: 
                node<T>* head_node; 
                static void generic_insert(node<T>* p_beg, node<T>* p_mid, node<T>* p_end)
                {
                    p_mid->next = p_end; 
                    p_mid->prev = p_beg; 
                    p_beg->next = p_mid; 
                    p_end->prev = p_mid; 
                }

                static void generic_delete(node<T>* p_delete_node)
                {
                    p_delete_node->prev->next = p_delete_node->next; 
                    p_delete_node->next->prev = p_delete_node->prev; 
                    delete p_delete_node; 
                    p_delete_node = 0; 
                }

                node<T>* search_node(T const& searchData)
                {
                    for(node<T>* run = head_node->next; run != head_node; run = run->next)
                        if(run->data == searchData)
                            return run; 
                    return 0; 
                }

            public: 
                list() : head_node(new node<T>), 
                {
                    head_node->prev = head_node; 
                    head_node->next = head_node; 
                }

                void insert_start(T const& data)
                {
                    generic_insert(head_node, new node<T>(data), head_node->next); 
                }

                void insert_end(T const& data)
                {
                    generic_insert(head_node->prev, new node<T>(data), head_node); 
                }
        };
    }
}