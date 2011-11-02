using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TestApp
{
    class Program
    {
        static void Main(string[] args)
        {
            String s = String.Empty;
            Console.WriteLine("Hello USAToday!");
            s = Console.ReadLine();
            Console.WriteLine(String.Format("You have entered: {0}\nPress any key to exit program.", s));
            Console.ReadKey();

            //this is Sparta!
        }
    }
}
