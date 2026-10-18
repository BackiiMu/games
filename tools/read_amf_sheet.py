"""Read the limited AMF3 SheetData format embedded in EF.swf."""
import json
import struct
import sys
from pathlib import Path


class Reader:
    def __init__(self, data):
        self.data = data
        self.pos = 0
        self.strings = []
        self.objects = []
        self.traits = []

    def byte(self):
        value = self.data[self.pos]
        self.pos += 1
        return value

    def u29(self):
        result = 0
        for index in range(4):
            value = self.byte()
            if index == 3:
                return (result << 8) | value
            result = (result << 7) | (value & 127)
            if value < 128:
                return result
        raise ValueError("invalid U29")

    def string(self):
        head = self.u29()
        if not head & 1:
            return self.strings[head >> 1]
        length = head >> 1
        value = self.data[self.pos:self.pos + length].decode("utf-8")
        self.pos += length
        if length:
            self.strings.append(value)
        return value

    def value(self):
        marker = self.byte()
        if marker in (0, 1):
            return None
        if marker == 2:
            return False
        if marker == 3:
            return True
        if marker == 4:
            value = self.u29()
            return value - 0x20000000 if value & 0x10000000 else value
        if marker == 5:
            value = struct.unpack_from(">d", self.data, self.pos)[0]
            self.pos += 8
            return value
        if marker == 6:
            return self.string()
        if marker == 9:
            head = self.u29()
            if not head & 1:
                return self.objects[head >> 1]
            dense_length = head >> 1
            associative = {}
            while name := self.string():
                associative[name] = self.value()
            value = []
            self.objects.append(value)
            value.extend(self.value() for _ in range(dense_length))
            return associative or value
        if marker == 10:
            head = self.u29()
            if not head & 1:
                return self.objects[head >> 1]
            if not head & 2:
                trait = self.traits[head >> 2]
            else:
                class_name = self.string()
                names = [self.string() for _ in range(head >> 4)]
                trait = (class_name, names, bool(head & 8))
                self.traits.append(trait)
            class_name, names, dynamic = trait
            value = {"_class": class_name}
            self.objects.append(value)
            for name in names:
                value[name] = self.value()
            if dynamic:
                while name := self.string():
                    value[name] = self.value()
            return value
        if marker == 16:
            head = self.u29()
            if not head & 1:
                return self.objects[head >> 1]
            length = head >> 1
            self.byte()  # fixed-length flag
            class_name = self.string()
            value = []
            self.objects.append(value)
            value.extend(self.value() for _ in range(length))
            return value
        raise ValueError(f"unknown marker {marker} at offset {self.pos - 1}")


if __name__ == "__main__":
    document = Reader(Path(sys.argv[1]).read_bytes()).value()
    output = json.dumps({entry["name"]: [entry["x"], entry["y"], entry["width"], entry["height"]]
                         for entry in document["list"]}, ensure_ascii=False, separators=(",", ":"))
    if len(sys.argv) > 2:
        Path(sys.argv[2]).write_text(output, encoding="utf-8")
    else:
        print(output)
