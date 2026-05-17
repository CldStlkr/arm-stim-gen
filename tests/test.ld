SECTIONS
{
  . = 0x400000;
  .text : { *(.text) }

  . = 0x410000;
  .results (NOLOAD) : { . += 0x100; }
}
