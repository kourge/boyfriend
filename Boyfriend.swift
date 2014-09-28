
/**
    A Brainfuck command.
*/
public enum Op: Character {
    case Incr = "+"
    case Decr = "-"
    case Next = ">"
    case Prev = "<"
    case Loop = "["
    case End = "]"
    case Put = "."
    case Get = ","
}

/**
    An infinite tape that acts as memory for a Brainfuck program.
*/
public struct Tape {
    /// The default value of an unmanipulated cell.
    static let DEFAULT: Int = 0
    
    /// The infinite tape to which a Brainfuck program has access, implemented
    /// with a sparse map.
    internal(set) var tape: [Int : Int]
    
    /// Initialize an empty tape.
    public init() {
        tape = [Int : Int]()
    }
    
    /**
        Get the value at the specified index on this tape. If the cell has not
        been manipulated before, the default value is returned.

        :param: index The index of the cell on the tape
    */
    public func value(atIndex index: Int) -> Int {
        return tape[index] ?? Tape.DEFAULT
    }
    
    /**
        Set the value at the specified index on this tape to a constant value.

        :param: value The value to set the cell to
        :param: index The index of the cell on the tape
    */
    public mutating func set(#value: Int, atIndex index: Int) -> Void {
        tape[index] = value
    }
    
    /**
        Shift the value at the specified index on this tape by offset.
    
        :param: offset The delta by which to shift the cell value
        :param: index The index of the cell on the tape
    */
    public mutating func shift(by offset: Int, atIndex index: Int) -> Void {
        if let existing = tape[index] {
            tape[index] = existing + offset
        } else {
            tape[index] = Tape.DEFAULT + offset
        }
    }
    
    public subscript(index: Int) -> Int {
        get {
            return value(atIndex: index)
        }
        
        set(newValue) {
            set(value: newValue, atIndex: index)
        }
    }
}

/**
    A Brainfuck program, consisting of an array of Ops.
*/
public struct Program {
    /// The program, consisting of an array of Ops.
    internal(set) var program: [Op]
    
    /// Initialize an empty program.
    public init() { program = [Op]() }
    
    /**
        Initialize a program with the given commands.
        
        :param: ops An array of Ops, each of which represent a Brainfuck
                    command
    */
    public init(ops: [Op]) { program = ops }
    
    /**
        Initializes a program using the provided string as source code. Only
        Brainfuck commands are parsed; the rest are ignored.
    
        :param: source The source code of the Brainfuck program in the form
                of a String.
    */
    public init(source: String) {
        program = [Op]()
        for char in source {
            if let op = Op(rawValue: char) {
                program.append(op)
            }
        }
    }
    
    /**
        Run the program with the given input / output sources.
    
        :param: output The output, which can be an inout String.
        :param: input The input, which can be any SequenceType whose elements
                are characters
    */
    public func run<
        O: OutputStreamType,
        I: SequenceType where I.Generator.Element == Character
    >(inout #output: O, input: I) -> Tape {
        let end = program.count
        var ip = 0
        var stack = [Int]()
        
        var tape = Tape()
        var index = 0
        
        var inputGenerator = input.generate()
        
        while ip != end {
            switch program[ip] {
            case .Incr: tape.shift(by: 1, atIndex: index)
            case .Decr: tape.shift(by: -1, atIndex: index)
            case .Next: index++
            case .Prev: index--
            case .Put:
                let char = Character(UnicodeScalar(tape[index]))
                output.write(String(char))
            case .Get:
                let char = inputGenerator.next()!
                let scalars = String(char).unicodeScalars
                let i = scalars[scalars.startIndex].value
                tape.set(value: Int(i), atIndex: index)
            case .Loop:
                stack.append(ip)
            case .End:
                if tape[index] != 0 {
                    ip = stack.last!
                } else {
                    stack.removeLast()
                }
            }
            ip++
        }
        
        return tape
    }
}
