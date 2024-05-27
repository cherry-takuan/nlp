{
    a=0;
    b=1;
    c=0;
    for(i=0;i<=10;i=i+1){
        c = a+b;
        a = b;
        b = c;
    }
    return c;
}