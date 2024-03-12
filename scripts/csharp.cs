using Godot;
using System;
using System.Runtime.InteropServices;

public class CSharp : Node
{
	[DllImport("Pito.dll", CallingConvention = CallingConvention.StdCall)]
	public static BugTrap(string text);
	
}