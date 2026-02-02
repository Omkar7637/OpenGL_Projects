#include <iostream> 
#include <stdexcept> 

class node 
{
    friend class list; 
    friend std::ostream& operator<<(std::ostream& os, const list& list_object); 
    private: 
        int data; 
        node* prev; 
        node* next; 
        node(int _data = 0) : data(_data), prev(0), next(0)
        {

        }
};  

class list 
{
    friend std::ostream& operator<<(std::ostream& os, const list& list_object); 
    private: 
        node* head_node; 

        static void generic_insert(node* p_beg, node* p_mid, node* p_end) 
        {
            p_mid->next = p_end; 
            p_mid->prev = p_beg; 
            p_beg->next = p_mid; 
            p_end->prev = p_mid; 
        }

        static void generic_delete(node* p_delete_node)
        {
            p_delete_node->prev->next = p_delete_node->next; 
            p_delete_node->next->prev = p_delete_node->prev; 
            delete p_delete_node; 
            p_delete_node = 0; 
        }

        node* search_node(int search_data) 
        {
            for(node* run = head_node->next; run != head_node; run = run->next)
                if(run->data == search_data)
                    return run; 
            return 0; 
        }

    public: 
        list() : head_node(new node)
        {
            head_node->prev = head_node; 
            head_node->next = head_node; 
        }

        void insert_start(int data)
        {
            generic_insert(head_node, new node(data), head_node->next); 
        }

        void insert_end(int data)
        {
            generic_insert(head_node->prev, new node(data), head_node); 
        }

        void insert_after(int existing_data, int new_data)
        {
            node* existing_node = search_node(existing_data); 
            if(existing_node == 0)
                throw std::runtime_error("invalid data"); 
            generic_insert(existing_node, new node(new_data), existing_node->next); 
        }

        void insert_before(int existing_data, int new_data)
        {
            node* existing_node = search_node(existing_data); 
            if(existing_node == 0)
                throw std::runtime_error("invalid data"); 
            generic_insert(existing_node->prev, new node(new_data), existing_node); 
        }

        int get_start()
        {
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            return head_node->next->data; 
        }

        int get_end()
        {   
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            return head_node->prev->data; 
        }

        int pop_start()
        {
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            int tmp = head_node->next->data; 
            generic_delete(head_node->next); 
            return tmp; 
        }

        int pop_end()
        {
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            int tmp = head_node->prev->data; 
            generic_delete(head_node->prev); 
            return tmp; 
        }

        void remove_start() 
        {
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            generic_delete(head_node->next); 
        }

        void remove_end()
        {
            if(head_node->prev == head_node && head_node->next == head_node)
                throw std::runtime_error("list empty"); 
            generic_delete(head_node->prev); 
        }

        void remove_data(int r_data)
        {
            node* r_node = search_node(r_data); 
            if(!r_node)
                std::runtime_error("invalid data"); 
            generic_delete(r_node); 
        }

        std::size_t len() const 
        {
            std::size_t L = 0; 
            for(node* run = head_node->next; run != head_node; run = run->next)
                ++L; 
            return L; 
        }

        ~list() 
        {
            node* run, *run_next; 

            run = head_node->next; 
            while(run != head_node)
            {
                run_next = run->next; 
                delete run; 
                run = run_next; 
            }

            delete head_node; 
            head_node = 0; 
        }

        class iterator 
        {
            private: 
                node* N; 
            public:
                iterator(node* _N = 0) : N(_N) 
                {

                }

                int operator*() 
                {
                    return N->data; 
                }

                bool operator==(const iterator& other)
                {
                    return N == other.N; 
                }

                bool operator!=(const iterator& other)
                {
                    return N != other.N; 
                }

                iterator& operator++()
                {
                    N = N->next; 
                    return *this;
                }

                iterator& operator--()
                {
                    N = N->prev; 
                    return *this; 
                }

                iterator operator++(int)
                {
                    iterator tmp(N); 
                    N = N->next; 
                    return tmp; 
                }

                iterator operator--(int)
                {
                    iterator tmp(N); 
                    N = N->prev; 
                    return tmp; 
                }
        }; 

        iterator begin() 
        {
            return iterator(head_node->next); 
        }

        iterator end() 
        {
            return iterator(head_node); 
        }
}; 

std::ostream& operator<<(std::ostream& os, const list& list_object) 
{
    node* head_node = list_object.head_node; 
    os << "[START]<->"; 
    for(node* run = head_node->next; run != head_node; run = run->next)
        os << "[" << run->data << "]<->"; 
    os << "[END]" << std::endl; 
    return os; 
}

void basic_testing(void); 

int main(void)
{
    basic_testing(); 
    return EXIT_SUCCESS;     
}

void basic_testing(void)
{
    list L; 

    for(int data = 10; data <= 100; data += 10)
        L.insert_end(data); 

    std::cout << "Showing list L:" << L << std::endl; 

    std::cout << "Showing list L by iterating over it:" << std::endl; 
    for(list::iterator iter = L.begin(); iter != L.end(); ++iter)
        std::cout << "*iter =" << *iter << std::endl; 
}