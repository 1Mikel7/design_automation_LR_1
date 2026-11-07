#include <iostream>
#include <iomanip>

int main() {
    unsigned int number = 3;
    std::cout << "Student number: " << number
              << " = 0x" << std::hex << std::setw(8) << std::setfill('0')
              << number << std::endl;
    return 0;
}